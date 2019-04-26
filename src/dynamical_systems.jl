# ## Inhibition Radius
"""
The inhibition radius of a Spatial Pooler's columns is a dynamical system that evolves
under the influence of other elements of the Spatial Pooler. It provides an init
(constructor) and a step! function.
"""
mutable struct InhibitionRadius <:AbstractFloat
  φ::Float32
  InhibitionRadius(x,spaceSizeRatio,enable_local_inhibit=true)= enable_local_inhibit ?
      (x>=0 ? begin
        inv1(r)= r<1 ? 1/r : r
        closestToUnity= spaceSizeRatio[argmin(inv1.(spaceSizeRatio))]
        new(x * closestToUnity)
      end : error("Inhibition radius >0")) :
      new(Inf)
end
Base.convert(::Type{InhibitionRadius}, x::InhibitionRadius)= x
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
  smin= SynapsePermanenceQuantization(1)
  synapses_activeSP= @view s.synapses[:,a]
  activeConn=   @. synapses_activeSP>0 &  z
  inactiveConn= @. synapses_activeSP>0 & !z
  # Learn synapse permanences according to Hebbian learning rule
  @inbounds @. (synapses_activeSP= activeConn * min(smax,synapses_activeSP+params.p⁺) +
      inactiveConn * max(smin,synapses_activeSP-params.p⁻))
  # Update cache of connected synapses
  @inbounds s.connected[:,vec(a)].= synapses_activeSP .> params.θ_permanence_prox
end
connected(s::ProximalSynapses)= s.connected

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

function step!(s::Boosting, a_t::CellActivity, φ,T,β)
  α(φ)= 2*floor(Int,φ)+1   # neighborhood side
  a_Nmean!(aN,aT)= imfilter!(aN,aT, ones(α(φ),α(φ))/α(φ)^2, "symmetric")

  s.a_Tmean.= s.a_Tmean*(T-1)/T .+ a_t/T
  a_Nmean!(s.a_Nmean, s.a_Tmean)
  s.b.= boostfun.(s.a_Tmean, s.a_Nmean, β)|> vec
end
boostfun(a_Tmean,a_Nmean,β)= ℯ^(-β*(a_Tmean-a_Nmean))
