include("common.jl")
include("utils/topology.jl")
include("algorithm_parameters.jl")
include("dynamical_systems.jl")

struct SpatialPooler{Nin,Nsp} #<: Region
  params::SPParams
  proximalSynapses::ProximalSynapses
  φ::InhibitionRadius
  b::Boosting

  # Nin, Nsp: number of input and spatial pooler dimensions
  function SpatialPooler(params::SPParams{Nin,Nsp}) where {Nin,Nsp}
    @unpack szᵢₙ,szₛₚ,θ_potential_prob,θ_permanence,γ,
            enable_local_inhibit  = params

    synapseSparsity= (1-θ_potential_prob)*(enable_local_inhibit ?
                        (α(γ)^Nin)/prod(szᵢₙ) : 1)
    new{Nin,Nsp}(params,
        ProximalSynapses(szᵢₙ,szₛₚ,synapseSparsity,
            γ,θ_potential_prob,θ_permanence),
        InhibitionRadius(γ,szᵢₙ, szₛₚ./szᵢₙ, enable_local_inhibit),
        Boosting(ones(prod(szₛₚ)), szₛₚ)
    )
  end
end


"""
      step!(z::CellActivity, sp::SpatialPooler)

  Evolve the Spatial Pooler to the next timestep.
"""
function step!(sp::SpatialPooler, z::CellActivity)
  # Activation
  a= sp_activation(sp.proximalSynapses,sp.φ.φ,sp.b,z, sp.params)
  # Learning
  if sp.params.enable_learning
    step!(sp.proximalSynapses, z,a,sp.params)
    step!(sp.b, a,sp.φ.φ,sp.params.Tboost,sp.params.β,
          sp.params.enable_local_inhibit,sp.params.enable_boosting)
    step!(sp.φ, a,connected(sp.proximalSynapses), sp.params)
  end
  return a
end

function sp_activation(synapses,φ,b,z, params)
  @unpack szₛₚ, s, θ_stimulus_activate, enable_local_inhibit = params
  # Definitions taken directly from [section 2, doi: 10.3389]
  area= enable_local_inhibit ? α(φ)^length(szₛₚ) : prod(szₛₚ)
  n_active_perinhibit= ceil(Int,s*area)
  # W: Connected synapses (size: proximalSynapses)
  W()= connected(synapses)
  # o: overlap
  o(W)= @> (b .* (W'*z)) reshape(szₛₚ)
  # Z: k-th larger overlap in neighborhood
  # OPTIMIZE: local inhibition is the SP's bottleneck. "mapwindow" is suboptimal;
  #   https://github.com/JuliaImages/Images.jl/issues/751
  θ_inhibit!(v)= @> v vec partialsort!(n_active_perinhibit,rev=true)
  _Z(::Val{true},o)= mapwindow(θ_inhibit!, o, ntuple(i->α(φ),length(szₛₚ)), border=Fill(0))
  _Z(::Val{false},o)= θ_inhibit!(copy(o))
  Z(o)= _Z(Val(enable_local_inhibit),o)
  # a: activation
  a(o)= (o .>= Z(o)) .& (o .> θ_stimulus_activate)

  W()|> o|> a
end
