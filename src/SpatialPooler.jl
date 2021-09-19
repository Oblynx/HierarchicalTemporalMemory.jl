"""
`SpatialPooler` is a learning algorithm that decorrelates the features of an input space,
producing a Sparse Distributed Representation (SDR) of the input space.
If defines the proximal connections of an HTM layer.

# Examples
```julia
sp= SpatialPooler(SPParams(szᵢₙ=(600,), szₛₚ=(2048,)))
z= Random.bitrand(600)  # input
activation= sp(z)
# or, to adapt the SP to the input as well:
activation= step!(sp,z)
```

# Properties

It's called `SpatialPooler` because input patterns that share a large number of co-active neurons
(i.e., that are spatially similar) are grouped together into a common output representation.
It is designed to achieve a set of _computational properties_ that support further downstream computations with SDRs, including:

- preserving topology of the input space by mapping similar inputs to similar outputs
- continuously adapting to changing statistics of the input stream
- forming fixed sparsity representations
- being robust to noise
- being fault tolerant

[Source](https://www.frontiersin.org/articles/10.3389/fncom.2017.00111/full)

# Algorithm overview

## Mapping I/O spaces

The spatial pooler maps an input space `x` to an output space `y` of minicolumns through a matrix of proximal synapses.
The input space can optionally have a topology, which the spatial pooler will preserve by mapping
output minicolumn `yᵢ` to a subset of the input space, a [`Hypercube`](@ref) around center `xᶜ`.
```julia
xᶜ(yᵢ)= floor.(Int, (yᵢ.-1) .* (szᵢₙ./szₛₚ)) .+1
````

## Output activation

1. Calculate the overlap `o(yᵢ)` by propagating the input activations through the proximal synapses
   and adjusting by boosting factors `b` (control mechanism that spreads out the activation pattern
   across understimulated neurons)
2. Inhibition `Z` between `yᵢ` (local/global): competition where only the top-K `yᵢ` with the highest `o(yᵢ)` win; ensures sparsity
3. Activate winning `yᵢ` > activation threshold (`θ_stimulus_activate`)

See also: [`sp_activate`](@ref)

# State variables

- `synapses`: includes the synapse permanence matrix Dₚ
- `åₜ`: [boosting] moving (in time) average (in time) activation of each minicolumn
- `åₙ`: [boosting] moving (in time) average (in neighborhood) activation of each minicolumn
- `φ`: the adaptible radius of local inhibition

---
See also: [`ProximalSynapses`](@ref), [`TemporalMemory`](@ref)
"""
struct SpatialPooler
  params::SPParams
  # includes the permanence matrix Dₚ
  synapses::ProximalSynapses
  φ::Vector{Float32}  # vector instead of Float32 for mutating
  # Boosting
  "boosting factors"
  b::Vector{Float32}
  "[boosting] average in time activation of each minicolumn"
  åₜ::Array{Float32}
  "[boosting] average in neighborhood activation of each minicolumn"
  åₙ::Array{Float32}
end
function SpatialPooler(params::SPParams)
  params= normalize_SPparams(params)
  @unpack szᵢₙ,szₛₚ,prob_synapse,θ_permanence,γ,
          enable_local_inhibit = params

  synapseSparsity= prob_synapse * (enable_local_inhibit ?
                      (α(γ)^length(szᵢₙ))/prod(szᵢₙ) : 1)
  SpatialPooler(params,
      ProximalSynapses(szᵢₙ,szₛₚ,synapseSparsity,γ,
          prob_synapse,θ_permanence, topology= enable_local_inhibit),
      init_φ(γ,prob_synapse,szᵢₙ,szₛₚ),
      ones(prod(szₛₚ)), zeros(szₛₚ), zeros(szₛₚ)
  )
end
init_φ(γ,prob_synapse,szᵢₙ,szₛₚ)= [((2γ+0.5)*prob_synapse*mean(szₛₚ./szᵢₙ) - 1)/2]
b(sp::SpatialPooler)= sp.params.enable_boosting ? ones(length(sp.b)) : sp.b
åₙ(sp::SpatialPooler)= sp.åₙ
Wₚ(sp::SpatialPooler)= Wₚ(sp.synapses)
φ(sp::SpatialPooler)= sp.φ[1]

reset!(sp::SpatialPooler)= begin
  @unpack szᵢₙ,szₛₚ,prob_synapse,γ = sp.params
  reset!(sp.synapses)
  sp.φ.= init_φ(γ,prob_synapse,szᵢₙ,szₛₚ)
  sp.b.= 1.0
  sp.åₜ.= 0.0
  sp.åₙ.= 0.0
end

# SP activation

"""
Return the activation pattern of the [`SpatialPooler`](@ref) for the given input activation.

`z`: [`CellActivity`](@ref)

# Example
```julia
sp= SpatialPooler(SPParams(szᵢₙ=(600,), szₛₚ=(2048,)))
z= Random.bitrand(600)  # input
activation= sp(z)
# or, to adapt the SP to the input as well:
activation= step!(sp,z)
```

For details see: [`sp_activate`](@ref)
"""
(sp::SpatialPooler)(z)= sp_activate(sp,z)

"""
`sp_activate(sp::SpatialPooler, z)` calculates the SP's output activation for given input activation `z`.

# Algorithm

1. Overlap `o(yᵢ)`
    - Propagate the input activations through the proximal synapses (matrix multiply)
    - Apply boosting factors `b`: control mechanism that spreads out the activation pattern across understimulated
      neurons (homeostatic excitability control)
2. Inhibition `Z` between `yᵢ` (local/global): competition where only the top-k `yᵢ` with the highest `o(yᵢ)` win; ensures sparsity
   The competition happens within an area around each neuron.
    - `k`: number of winners depends on desired sparsity (`s`, see [`SPParams`](@ref)) and area size
    - `θ_inhibit`: inhibition threshold per neighborhood ``:= o(k-th y)``
    - `Z(o(yᵢ))`: convolution of `o` with `θ_inhibit`
3. Activate winning `yᵢ` > activation threshold (`θ_stimulus_activate`)

!!! info
    The local sparsity `s` tends to the sparsity of the entire layer as it grows larger, but for small values or small inhibition radius
    it diverges, because of the limited & integral number of neurons winning in each neighborhood.
    This could be addressed by *tie breaking*, but it doesn't seem to have much practical importance.
"""
function sp_activate(sp::SpatialPooler, z)
  @unpack szₛₚ,s,θ_permanence,θ_stimulus_activate,enable_local_inhibit = sp.params

  # overlap
  overlap(z)= @chain vec(z) begin
    Wₚ(sp)' * _
    θ_activation.(_)
    b(sp) .* _
    reshape(szₛₚ)
  end
  θ_activation(x)= x .> θ_stimulus_activate ? x : 0

  # inhibition
  area()= enable_local_inhibit ? α(φ(sp))^length(szₛₚ) : prod(szₛₚ)
  k()=    ceil(Int, s*area())
  # inhibition threshold per area
  # OPTIMIZE: local inhibition is the SP's bottleneck. "mapwindow" is suboptimal;
  #   https://github.com/JuliaImages/Images.jl/issues/751
  θ_inhibit!(X)= @> X vec partialsort!(k(),rev=true)
  # Z: k-th largest overlap in neighborhood
  Z(y)= _Z(Val(enable_local_inhibit),y)
  # we increase the threshold a bit to account stochastically for the error in approximating k and for tiebreaking
  _Z(loc_inhibit::Val{true}, y)= @> mapwindow(θ_inhibit!, y, neighborhood(φ(sp),length(szₛₚ)), border=Fill(0))
  _Z(loc_inhibit::Val{false},y)= @> θ_inhibit!(copy(y))
  Z_perm(y)= partialsortperm(y, 1:k(), rev=true)

  # Tiebreaker
  sErr()= 1 - k() + s*area()
  tieEst(o,Z)= count(o .== Z) * area()/prod(szₛₚ)
  tiebreaker(o,Z)= rand(Float32,szₛₚ) .- (1 - sErr()/tieEst(o,Z))
  activate_tiebreaker(o)= begin
    Z= Z(o)
    (o .+ tiebreaker(o,Z) .>= Z)
  end

  if enable_local_inhibit
    @chain z begin
      overlap
      activate_tiebreaker
    end
  else
    @chain z begin
      overlap
      Z_perm
      bitarray(_, szₛₚ)
    end
  end
end

# SP adaptation

"""
`step!(sp::SpatialPooler, z::CellActivity)` evolves the Spatial Pooler to the next timestep
by evolving each of its constituents (synapses, boosting, inhibition radius)
and returns the output activation.

See also: [`sp_activate`](@ref)
"""
function step!(sp::SpatialPooler, z)
  a= sp_activate(sp, z)
  if sp.params.enable_learning
    step!(sp.synapses, z,a, sp.params)
    step_boost!(sp,a)
    # φ kept static for the moment (no obvious benefit from dynamic φ)
    #nupic_update_φ!(sp)
  end
  return a
end

# # boosting
"""
`step_boost!(sp::SpatialPooler,a)` evolves the boosting factors `b` (see [`sp_activate`](@ref)).
They depend on:
- `åₜ`: moving average in time activation of each minicolumn
- `åₙ`: moving average in neighborhood activation of each minicolum
"""
step_boost!(sp::SpatialPooler,a)= begin
  @unpack Tboost,β, szₛₚ= sp.params
  step_åₙ!(sp)
  # exponential moving average with period Tboost
  sp.åₜ.= (sp.åₜ.*(Tboost-1) .+ reshape(a,szₛₚ))./Tboost
  sp.b.= boostfun(sp.åₜ,sp.åₙ,β)
end
boostfun(åₜ,åₙ,β)= @> exp.(-β .* (åₜ .- åₙ)) vec
step_åₙ!(sp::SpatialPooler)= begin
  # local mean filter
  _step_åₙ!(sp::SpatialPooler,local_inhibit::Val{true})=
      imfilter!(sp.åₙ,sp.åₜ, mean_kernel(φ(sp),length(sp.params.szₛₚ)), "symmetric")
  _step_åₙ!(sp::SpatialPooler,local_inhibit::Val{false})= (sp.åₙ.= mean(sp.åₜ))

  _step_åₙ!(sp,Val(sp.params.enable_local_inhibit))
end

# # Inhibition radius

# This implementation follows the SP paper description and NUPIC, but seems too complex
#   for no reason. Replace with a static inhibition radius instead
nupic_update_φ!(sp::SpatialPooler)= begin
  @unpack szₛₚ, szᵢₙ, prob_synapse = sp.params
  # sample 10% of minicolumns
  mean_receptiveFieldSpan()= (i-> receptivefieldSpan(szᵢₙ,Wₚ(sp)[:,i]) ).( randperm(size(Wₚ(sp),2))[1:100] ) |> mean
  #mean_receptiveFieldSpan()= mapslices(receptivefieldSpan, W, dims=1)|> mean
  # Simplified version:
  #mean_receptiveFieldSpan()= (2γ+0.5) * prob_synapse
  receptiveFieldSpan_yspace()= ( mean_receptiveFieldSpan()*mean(szₛₚ./szᵢₙ) - 1)/2
  sp.φ[1]= max(receptiveFieldSpan_yspace(), 1)
end

# Foreach minicolumn, find the geometric span of its projection to the input space through the connected synapses
# foreach dimension, then return the mean
function receptivefieldSpan(sz_in, Wᵢ)
  c= CartesianIndices(sz_in)
  connectedInputXY= c[findall(Wᵢ)]
  maxc= [mapreduce(c->c.I[d], max, connectedInputXY) for d in 1:length(sz_in)]
  minc= [mapreduce(c->c.I[d], min, connectedInputXY) for d in 1:length(sz_in)]
  mean(maxc .- minc .+ 1)
end

normalize_SPparams(params)= begin
  params.szᵢₙ|> typeof <: Int ? (params = @set params.szᵢₙ = (params.szᵢₙ,)) : nothing
  params.szₛₚ|> typeof <: Int ? (params = @set params.szₛₚ = (params.szₛₚ,)) : nothing
  !params.enable_local_inhibit ? (params = @set params.γ = maximum(params.szᵢₙ)) : nothing
  params
end
