# ## Inhibition Radius
"""
The inhibition radius of a Spatial Pooler's columns is a dynamical system that evolves
under the influence of other elements of the Spatial Pooler. It provides an init
(constructor) and a step! function.
"""
mutable struct InhibitionRadius <:AbstractFloat
  φ::Float32
  InhibitionRadius(x,enable_local_inhibit=true)= enable_local_inhibit ?
      (x>=0 ? new(x) : error("Inhibition radius >0")) :
      new(Inf)
end
#Base.convert(::Type{InhibitionRadius}, x::T) where {T<:Number}= InhibitionRadius(x)
Base.convert(::Type{N}, x::InhibitionRadius) where {N<:Number}= convert(N,x.φ)
Base.promote_rule(::Type{InhibitionRadius}, ::Type{T}) where {T<:Number}= Float32
Float32(x::InhibitionRadius)= x.φ
Int(x::InhibitionRadius)= round(Int,x.φ)

function step!(s::InhibitionRadius, z::CellActivity)
end

# ## Proximal Synapses
const permT= SynapsePermanenceQuantization
struct ProximalSynapses
  synapses::DenseSynapses
  connected::BitArray

  """
  Make an input x spcols synapse permanence matrix
  params: includes size (num of cols)
  Initialize potential synapses. For every column:
  - find its center in the input space
  - for every input in hypercube, draw rand Z
    - If < 1-θ_potential_prob_prox
     - Init perm: rescale Z from [0..1-θ] -> [0..1]: Z/(1-θ)
  """
  function ProximalSynapses(inputSize,spSize,input_potentialRadius,
        θ_potential_prob_prox,θ_permanence_prox)
    spColumns()= CartesianIndices(spSize)
    # Map column coordinates to their center in the input space. Column coords FROM 1 !!!
    xᶜ(yᵢ)= floor.(UIntSP, (yᵢ.-1) .* (inputSize./spSize)) .+1
    xᵢ(xᶜ)= hypercube(xᶜ,input_potentialRadius, inputSize)

    # Draw permanences from uniform distribution. Connections aren't very sparse (40%),
    #   so prefer a dense matrix
    #permanence_sparse(xᵢ)= sprand(permT,length(xᵢ),1, 1-θ_potential_prob_prox)
    permanence_dense(xᵢ)= begin
      p= rand(permT,length(xᵢ),1)
      effective_θ= floor(permT, (1-θ_potential_prob_prox)*typemax(permT))
      p0= p .> effective_θ; pScale= p .< effective_θ
      fill!(view(p,p0), permT(0))
      rand!(view(p,pScale), permT)
      return p
    end
    fillin!(proximalSynapses::AbstractSynapses)= begin
      for yᵢ in spColumns()
        yᵢ= yᵢ.I
        xi= xᵢ(xᶜ(yᵢ))
        proximalSynapses[xi, yᵢ]= permanence_dense(xi)
      end
      return proximalSynapses
    end

    proximalSynapses= DenseSynapses(inputSize,spSize)
    fillin!(proximalSynapses)
    new(proximalSynapses, proximalSynapses .> θ_permanence_prox)
  end
end

function step!(s::ProximalSynapses, z::CellActivity, a::CellActivity, params)
  smax= typemax(SynapsePermanenceQuantization)
  smin= SynapsePermanenceQuantization(1); s0= SynapsePermanenceQuantization(0)
  @. (s.synapses[:,a]= ifelse(z,
    ifelse(s.synapses[:,a]>0, min(smax,s.synapses[:,a]+params.p⁺), s0),
    ifelse(s.synapses[:,a]>0, max(smin,s.synapses[:,a]-params.p⁻), s0)
  ))
  # Update cache of connected synapses
  @. s.connected= s.synapses > params.θ_permanence_prox
end
connected(s::ProximalSynapses)= s.connected

# ## Boosting factors
struct Boosting <:DenseArray{Float32,1}
  b::Vector{Float32}
  Boosting(b)= (b.>0)|> all ? new(b) : error("Boosting factors >0")
end
Base.size(b::Boosting)= size(b.b)
Base.getindex(b::Boosting, i::Int)= b.b[i]

function step!(s::Boosting, z::CellActivity)
end
