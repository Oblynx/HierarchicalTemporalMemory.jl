include("common.jl")
include("utils/topology.jl")
include("dynamical_systems.jl")
include("algorithm_parameters.jl")

struct SpatialPooler{Nin,Nsp} #<: Region
  params::SPParams{Nin,Nsp}
  synapses::ProximalSynapses
  φ::InhibitionRadius
  b::Vector{Float32}
  åₜ::Array{Float32}
  åₙ::Array{Float32}

  # Nin, Nsp: number of input and spatial pooler dimensions
  function SpatialPooler(params::SPParams{Nin,Nsp}) where {Nin,Nsp}
    @unpack szᵢₙ,szₛₚ,θ_potential_prob,θ_permanence,γ,
            enable_local_inhibit  = params

    synapseSparsity= (1-θ_potential_prob)*(enable_local_inhibit ?
                        (α(γ)^Nin)/prod(szᵢₙ) : 1)
    new{Nin,Nsp}(params,
        ProximalSynapses(szᵢₙ,szₛₚ,synapseSparsity,γ,
            θ_potential_prob,θ_permanence),
        InhibitionRadius(γ,θ_potential_prob,szᵢₙ,szₛₚ, enable_local_inhibit),
        ones(prod(szₛₚ)), zeros(szₛₚ), zeros(szₛₚ)
    )
  end
end
b(sp::SpatialPooler)= sp.b
åₙ(sp::SpatialPooler)= sp.åₙ
Wₚ(sp::SpatialPooler)= Wₚ(sp.synapses)

# boosting
step_åₙ!(sp::SpatialPooler)= step_åₙ!(sp,Val(sp.params.enable_local_inhibit))
step_åₙ!(sp::SpatialPooler{Nin,Nsp},::Val{true}) where{Nin,Nsp}=
    imfilter!(sp.åₙ,sp.åₜ, mean_kernel(sp.φ.φ,Nsp), "symmetric")
step_åₙ!(sp::SpatialPooler,::Val{false})= (sp.åₙ.= mean(sp.åₜ))
step_boost!(sp::SpatialPooler,a)= begin
  @unpack Tboost,β, szₛₚ= sp.params
  step_åₙ!(sp)
  sp.åₜ.= (sp.åₜ.*(Tboost-1) .+ reshape(a,szₛₚ))./Tboost
  sp.b.= boostfun(sp.åₜ,sp.åₙ,β)
end
boostfun(åₜ,åₙ,β)= @> exp.(-β .* (åₜ .- åₙ)) vec

"""
      step!(sp::SpatialPooler, z::CellActivity)

  Evolve the Spatial Pooler to the next timestep.
"""
function step!(sp::SpatialPooler, z::CellActivity)
  a= sp_activate(z,sp)
  if sp.params.enable_learning
    step!(sp.synapses, z,a, sp.params)
    step_boost!(sp,a)
    step!(sp.φ, sp.params)
  end
  return a
end

function sp_activate(z,sp::SpatialPooler{Nin,Nsp}) where {Nin,Nsp}
  @unpack szₛₚ,s,θ_permanence,θ_stimulus_activate,enable_local_inhibit = sp.params
  @unpack φ = sp.φ;
  # overlap
  o(z)= @> (b(sp) .* (Wₚ(sp)'z)) reshape(szₛₚ)
  # inhibition
  area()= enable_local_inhibit ? α(φ)^Nsp : prod(szₛₚ)
  k()=    ceil(Int, s*area())
  # Z: k-th larger overlap in neighborhood
  # OPTIMIZE: local inhibition is the SP's bottleneck. "mapwindow" is suboptimal;
  #   https://github.com/JuliaImages/Images.jl/issues/751
  θ_inhibit!(X)= @> X vec partialsort!(k(),rev=true)
  _Z(::Val{true},o)= mapwindow(θ_inhibit!, o, neighborhood(φ,Nsp), border=Fill(0))
  _Z(::Val{false},o)= θ_inhibit!(copy(o))
  Z(o)= _Z(Val(enable_local_inhibit),o)

  activate(o)= (o .>= Z(o)) .& (o .> θ_stimulus_activate)
  z|> o|> activate
end
