# ## Inhibition Radius
"""
The inhibition radius of a Spatial Pooler's columns is a dynamical system that evolves
under the influence of other elements of the Spatial Pooler. It provides an init
(constructor) and a step! function.
"""
mutable struct InhibitionRadius <:AbstractFloat
  φ::Float32
  InhibitionRadius(x)= x>=0 ? new(x) : error("Inhibition radius >0")
end
#Base.convert(::Type{InhibitionRadius}, x::T) where {T<:Number}= InhibitionRadius(x)
Base.convert(::Type{N}, x::InhibitionRadius) where {N<:Number}= convert(N,x.φ)
Base.promote_rule(::Type{InhibitionRadius}, ::Type{T}) where {T<:Number}= Float32
Float32(x::InhibitionRadius)= x.φ


# ## Proximal Synapses
const permT= SynapsePermanenceQuantization
mutable struct ProximalSynapses
  synapses::DenseSynapses

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
      p= rand(permT,size(xᵢ))
      effective_θ= floor(permT, (1-θ_potential_prob_prox)*typemax(permT))
      p[p .> effective_θ].= 0
      p[p .< effective_θ].= rand(permT, count(p.<effective_θ))
      return p
    end
    fill!(proximalSynapses::AbstractSynapses)= begin
      for yᵢ in spColumns()
        yᵢ= yᵢ.I
        xi= xᵢ(xᶜ(yᵢ))
        proximalSynapses[xi, yᵢ]= permanence_dense(xi);
      end
      return proximalSynapses
    end

    proximalSynapses= DenseSynapses(inputSize,spSize)
    new(fill!(proximalSynapses))
  end
end
