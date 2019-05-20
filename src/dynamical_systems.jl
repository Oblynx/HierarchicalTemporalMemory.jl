# ## Inhibition Radius

"""
The inhibition radius of a Spatial Pooler's columns is a dynamical system that evolves
under the influence of other elements of the Spatial Pooler. It provides an init
(constructor) and a step! function.
"""
mutable struct InhibitionRadius{Nin} <:AbstractFloat
  φ::Float32
  sp_input_ratio::Float32
  ci::CartesianIndices{Nin}
  InhibitionRadius(x,inputSize::NTuple{Nin,Int},sp_input_ratio,enable_local_inhibit=true) where Nin=
      enable_local_inhibit ?
        (x>=0 ? new{Nin}(x * mean(sp_input_ratio), mean(sp_input_ratio),
                          CartesianIndices(map(d->1:d, inputSize))) :
          error("Inhibition radius >0")) :
        new{0}(maximum(sp_input_ratio.*inputSize)+1)
end
Base.convert(::Type{InhibitionRadius}, x::InhibitionRadius)= x
Base.convert(::Type{N}, x::InhibitionRadius) where {N<:Number}= convert(N,x.φ)
Base.promote_rule(::Type{InhibitionRadius}, ::Type{T}) where {T<:Number}= Float32
Float32(x::InhibitionRadius)= x.φ
Int(x::InhibitionRadius)= round(Int,x.φ)

step!(s::InhibitionRadius{0}, a,W,params)= nothing
function step!(s::InhibitionRadius{Nin}, a, W, params) where Nin
  # This implementation follows the SP paper description and NUPIC, but seems too complex
  #   for no reason. Replace with a static inhibition radius instead
  #receptiveFieldSpan(colinputs)::Float32= begin
  #  connectedInputCoords= @>> colinputs findall getindex(s.ci)
  #  maxc= [mapreduce(c->c.I[d], max, connectedInputCoords) for d in 1:Nin]
  #  minc= [mapreduce(c->c.I[d], min, connectedInputCoords) for d in 1:Nin]
  #  mean(maxc .- minc .+ 1)
  #end
  #mean_receptiveFieldSpan()::Float32= mapslices(receptiveFieldSpan, W, dims=1)|> mean
  mean_receptiveFieldSpan()= (params.input_potentialRadius*2+0.5)*(1-params.θ_potential_prob_prox)
  diameter= mean_receptiveFieldSpan()*s.sp_input_ratio
  s.φ= @> (diameter-1)/2 max(1)
end


# ## Proximal Synapses

const permT= SynapsePermanenceQuantization
struct ProximalSynapses{SynapseT<:AbstractSynapses,ConnectedT}
  synapses::SynapseT
  connected::ConnectedT

  """
  Make an input x spcols synapse permanence matrix
  params: includes size (num of cols)
  Initialize potential synapses. For every column:
  - find its center in the input space
  - for every input in hypercube, draw rand Z
    - If < 1-θ_potential_prob_prox
     - Init perm: rescale Z from [0..1-θ] -> [0..1]: Z/(1-θ)
  """
  function ProximalSynapses(inputSize,spSize,synapseSparsity,input_potentialRadius,
        θ_potential_prob_prox,θ_permanence_prox)
    spColumns()= CartesianIndices(spSize)
    # Map column coordinates to their center in the input space. Column coords FROM 1 !!!
    xᶜ(yᵢ)= floor.(UIntSP, (yᵢ.-1) .* (inputSize./spSize)) .+1
    xᵢ(xᶜ)= hypercube(xᶜ,input_potentialRadius, inputSize)

    # Draw permanences from uniform distribution. Connections aren't very sparse (40%),
    #   so prefer a dense matrix
    permanences(::Type{SparseSynapses},xᵢ)= sprand(permT,length(xᵢ),1, 1-θ_potential_prob_prox)
    permanences(::Type{DenseSynapses}, xᵢ)= begin
      p= rand(permT(0):typemax(permT),length(xᵢ),1)
      effective_θ= floor(permT, (1-θ_potential_prob_prox)*typemax(permT))
      p0= p .> effective_θ; pScale= p .< effective_θ
      fill!(view(p,p0), permT(0))
      rand!(view(p,pScale), permT(0):typemax(permT))
      return p
    end
    fillin!(proximalSynapses)= begin
      for yᵢ in spColumns()
        yᵢ= yᵢ.I
        xi= xᵢ(xᶜ(yᵢ))
        proximalSynapses[xi, yᵢ]= permanences(SynapseT,xi)
      end
      return proximalSynapses
    end

    SynapseT= synapseSparsity<0.08 ? SparseSynapses : DenseSynapses
    ConnectedT= synapseSparsity<0.08 ? SparseMatrixCSC{Bool} : Matrix{Bool}
    proximalSynapses= SynapseT(inputSize,spSize)
    fillin!(proximalSynapses)
    new{SynapseT,ConnectedT}(proximalSynapses, proximalSynapses .> θ_permanence_prox)
  end
end
connected(s::ProximalSynapses)= s.connected

function adapt!(::DenseSynapses,s::ProximalSynapses, z,a, params)
  synapses_activeSP= @view s.synapses[:,a]
  activeConn=   @. (synapses_activeSP>0) &  z
  inactiveConn= @. (synapses_activeSP>0) & !z

  # Learn synapse permanences according to Hebbian learning rule
  @inbounds @. (synapses_activeSP= activeConn * (synapses_activeSP ⊕ params.p⁺) +
      inactiveConn * (synapses_activeSP ⊖ params.p⁻))
  # Update cache of connected synapses
  @inbounds s.connected[:,vec(a)].= synapses_activeSP .> params.θ_permanence_prox
end
function adapt!(::SparseSynapses,s::ProximalSynapses, z,a, params)
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach(s.synapses,a) do s,ci,input_i
    @inbounds synapses_activeCol= @view nonzeros(s)[ci]
    @inbounds z_i= z[input_i]
    @inbounds synapses_activeCol.= z_i .* (synapses_activeCol .⊕ params.p⁺) .+
                                 .!z_i .* (synapses_activeCol .⊖ params.p⁻)
  end
  # Update cache of connected synapses
  @inbounds s.connected[:,a].= s.synapses.data[:,a] .> params.θ_permanence_prox
end
step!(s::ProximalSynapses, z,a, params)= adapt!(s.synapses, s,z,a,params)


# ## Boosting factors

struct Boosting <:DenseArray{Float32,1}
  b::Vector{Float32}
  a_Tmean::Array{Float32}
  a_Nmean::Array{Float32}
  Boosting(b,spSize)= (b.>0)|> all ? new(b, zeros(spSize), zeros(spSize)) :
                              error("Boosting factors >0")
end
Base.size(b::Boosting)= size(b.b)
Base.getindex(b::Boosting, i::Int)= b.b[i]

function step!(s::Boosting, a_t::CellActivity, φ,T,β, local_inhibit,enable)
  mean_kernel(Ndim)= ones(ntuple(i->α(φ),Ndim)) ./ α(φ).^Ndim
  a_Nmean!(aN,aT, local_inhibit::Val{true})=
      imfilter!(aN,aT, aN|>size|>length|>mean_kernel, "symmetric")
  a_Nmean!(aN,aT, local_inhibit::Val{false})= (aN.= mean(aT))

  s.a_Tmean.= s.a_Tmean*(T-1)/T .+ a_t/T
  a_Nmean!(s.a_Nmean, s.a_Tmean, Val(local_inhibit))
  if enable
    s.b.= boostfun.(s.a_Tmean, s.a_Nmean, β)|> vec
  end
end
boostfun(a_Tmean,a_Nmean,β)= ℯ^(-β*(a_Tmean-a_Nmean))


# ## Distal synapses for the TM
# (assume the same learning rule governs all types of distal synapses)

struct DistalSynapses
  synapses::SparseSynapses  # Nseg x Ncell
  cellSeg::SparseMatrixCSC{Bool,Int}
  connected::SparseMatrixCSC{Bool,Int}
end
cellXseg(s::DistalSynapses)= s.cellSeg
connected(s::DistalSynapses,θ)= s.synapses.data .> θ

function step!(s::DistalSynapses,previous::NamedTuple,A,c, params)
  @debug previous|>typeof
end
