receptiveFieldSpan(γ,θ_potential_prob)= (γ*2+0.5)*(1-θ_potential_prob)
receptiveFieldSpan_yspace(γ,θ_potential_prob,szᵢₙ,szₛₚ)=
    (receptiveFieldSpan(γ,θ_potential_prob)*mean(szₛₚ./szᵢₙ)-1)/2

@with_kw struct SPParams{Nin,Nsp}
  szᵢₙ::NTuple{Nin,Int}    = (32,32); @assert all(szᵢₙ.>0)
  szₛₚ::NTuple{Nsp,Int}    = (64,64); @assert all(szₛₚ.>0)
  γ::Int                   = 6;       @assert γ>0
  s::Float32               = .02;     @assert s>0
  θ_potential_prob::Float32= .5;      @assert 0<=θ_potential_prob<=1
  θ_permanence01           = .5;      @assert 0<=θ_permanence01<=1
  p⁺_01                    = .1;      @assert 0<=p⁺_01<=1
  p⁻_01                    = .02;     @assert 0<=p⁻_01<=1
  θ_permanence::𝕊𝕢       = @>> θ_permanence01*typemax(𝕊𝕢) round(𝕊𝕢)
  p⁺::𝕊𝕢                 = round(𝕊𝕢, p⁺_01*typemax(𝕊𝕢))
  p⁻::𝕊𝕢                 = round(𝕊𝕢, p⁻_01*typemax(𝕊𝕢))
  θ_stimulus_activate::Int = 1;       @assert θ_stimulus_activate>=0
  Tboost::Float32          = 200;     @assert Tboost>0
  β::Float32               = 1;       @assert β>0
  φ::Float32               = max(receptiveFieldSpan_yspace(γ,θ_potential_prob,szᵢₙ,szₛₚ), 1)
  @assert φ>=1
  @assert zero(𝕊𝕢)<=θ_permanence<=typemax(𝕊𝕢)
  @assert zero(𝕊𝕢)<=p⁺<=typemax(𝕊𝕢)
  @assert zero(𝕊𝕢)<=p⁻<=typemax(𝕊𝕢)


  inputSize::NTuple{Nin,Int}= szᵢₙ
  spSize::NTuple{Nsp,Int}= szₛₚ
  input_potentialRadius::Int= γ
  sp_local_sparsity::Float32= s
  T_boost::Float32= Tboost
  β_boost::Float32= β
  enable_local_inhibit::Bool= true
  enable_learning::Bool= true
  enable_boosting::Bool= true
  topologyWraps::Bool= false
end
