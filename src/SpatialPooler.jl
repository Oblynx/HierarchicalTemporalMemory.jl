#include("utils/topology.jl")
#include("dynamical_systems.jl")
#include("algorithm_parameters.jl")


"""
`SpatialPooler{Nin,Nsp}` is a learning algorithm that decorrelates the features of an input space,
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
struct SpatialPooler{Nin,Nsp} #<: Region
  params::SPParams{Nin,Nsp}
  # includes the permanence matrix Dₚ
  synapses::ProximalSynapses
  φ::InhibitionRadius
  # Boosting
  "boosting factors"
  b::Vector{Float32}
  "[boosting] average in time activation of each minicolumn"
  åₜ::Array{Float32}
  "[boosting] average in neighborhood activation of each minicolumn"
  åₙ::Array{Float32}

  # Nin, Nsp: number of input and spatial pooler dimensions
  function SpatialPooler(params::SPParams{Nin,Nsp}) where {Nin,Nsp}
    @unpack szᵢₙ,szₛₚ,prob_synapse,θ_permanence,γ,
            enable_local_inhibit  = params

    synapseSparsity= prob_synapse * (enable_local_inhibit ?
                        (α(γ)^Nin)/prod(szᵢₙ) : 1)
    new{Nin,Nsp}(params,
        ProximalSynapses(szᵢₙ,szₛₚ,synapseSparsity,γ,
            prob_synapse,θ_permanence),
        InhibitionRadius(γ,prob_synapse,szᵢₙ,szₛₚ, enable_local_inhibit),
        ones(prod(szₛₚ)), zeros(szₛₚ), zeros(szₛₚ)
    )
  end
end
b(sp::SpatialPooler)= sp.b
åₙ(sp::SpatialPooler)= sp.åₙ
Wₚ(sp::SpatialPooler)= Wₚ(sp.synapses)

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
`sp_activate(sp::SpatialPooler{Nin,Nsp}, z)` calculates the SP's output activation for given input activation `z`.

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
function sp_activate(sp::SpatialPooler{Nin,Nsp}, z) where {Nin,Nsp}
  @unpack szₛₚ,s,θ_permanence,θ_stimulus_activate,enable_local_inhibit = sp.params
  @unpack φ = sp.φ;
  # overlap
  o(z)= @> (b(sp) .* (Wₚ(sp)'z)) reshape(szₛₚ)

  # inhibition
  area()= enable_local_inhibit ? α(φ)^Nsp : prod(szₛₚ)
  k()=    ceil(Int, s*area())
  # inhibition threshold per area
  # OPTIMIZE: local inhibition is the SP's bottleneck. "mapwindow" is suboptimal;
  #   https://github.com/JuliaImages/Images.jl/issues/751
  θ_inhibit!(X)= @> X vec partialsort!(k(),rev=true)
  # Z: k-th larger overlap in neighborhood
  Z(y)= _Z(Val(enable_local_inhibit),y)
  _Z(loc_inhibit::Val{true}, y)= mapwindow(θ_inhibit!, y, neighborhood(φ,Nsp), border=Fill(0))
  _Z(loc_inhibit::Val{false},y)= θ_inhibit!(copy(y))

  activate(o)= (o .>= Z(o)) .& (o .> θ_stimulus_activate)
  z|> o|> activate
end

# SP adaptation

# boosting
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
  _step_åₙ!(sp::SpatialPooler{Nin,Nsp},local_inhibit::Val{true}) where{Nin,Nsp}=
      imfilter!(sp.åₙ,sp.åₜ, mean_kernel(sp.φ.φ,Nsp), "symmetric")
  _step_åₙ!(sp::SpatialPooler,local_inhibit::Val{false})= (sp.åₙ.= mean(sp.åₜ))

  _step_åₙ!(sp,Val(sp.params.enable_local_inhibit))
end

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
    step!(sp.φ, sp.params)
  end
  return a
end