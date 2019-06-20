receptiveFieldSpan(γ,θ_potential_prob)= (γ*2+0.5)*(1-θ_potential_prob)
receptiveFieldSpan_yspace(γ,θ_potential_prob,szᵢₙ,szₛₚ)=
    (receptiveFieldSpan(γ,θ_potential_prob)*mean(szₛₚ./szᵢₙ)-1)/2

@with_kw struct SPParams{Nin,Nsp}
  szᵢₙ::NTuple{Nin,Int}     = (32,32); @assert all(szᵢₙ.>0)
  szₛₚ::NTuple{Nsp,Int}     = (64,64); @assert all(szₛₚ.>0)
  γ::Int                    = 6;       @assert γ>0
  s::Float32                = .02;     @assert s>0
  θ_potential_prob::Float32 = .5;      @assert 0<=θ_potential_prob<=1
  θ_permanence01::Float32   = .5;      @assert 0<=θ_permanence01<=1
  p⁺_01::Float32            = .1;      @assert 0<=p⁺_01<=1
  p⁻_01::Float32            = .02;     @assert 0<=p⁻_01<=1
  θ_permanence::𝕊𝕢        = round(𝕊𝕢, θ_permanence01*typemax(𝕊𝕢))
  p⁺::𝕊𝕢                  = round(𝕊𝕢, p⁺_01*typemax(𝕊𝕢))
  p⁻::𝕊𝕢                  = round(𝕊𝕢, p⁻_01*typemax(𝕊𝕢))
  θ_stimulus_activate::Int  = 1;       @assert θ_stimulus_activate>=0
  Tboost::Float32           = 200;     @assert Tboost>0
  β::Float32                = 1;       @assert β>0
  φ::Float32                = max(receptiveFieldSpan_yspace(γ,θ_potential_prob,szᵢₙ,szₛₚ), 1)
  enable_local_inhibit::Bool= true
  enable_learning::Bool     = true
  enable_boosting::Bool     = true
  @assert φ>=1
  @assert zero(𝕊𝕢)<=θ_permanence<=typemax(𝕊𝕢)
  @assert zero(𝕊𝕢)<=p⁺<=typemax(𝕊𝕢)
  @assert zero(𝕊𝕢)<=p⁻<=typemax(𝕊𝕢)
end

@with_kw struct TMParams
  Nc::Int                  = 4096;    @assert Nc>0
  cellϵcol::Int            = 16;      @assert cellϵcol>0
  Nₙ::Int                  = Nc*cellϵcol;    @assert Nₙ>0
  p⁺_01::Float32           = .12;     @assert 0<=p⁺_01<=1
  p⁻_01::Float32           = .04;     @assert 0<=p⁻_01<=1
  LTD_p⁻_01::Float32       = .002;    @assert 0<=LTD_p⁻_01<=1
  p⁺::𝕊𝕢                 = round(𝕊𝕢,p⁺_01*typemax(𝕊𝕢))
  p⁻::𝕊𝕢                 = round(𝕊𝕢,p⁻_01*typemax(𝕊𝕢))
  LTD_p⁻::𝕊𝕢             = round(𝕊𝕢,LTD_p⁻_01*typemax(𝕊𝕢))
  θ_permanence_dist::𝕊𝕢  = round(𝕊𝕢,.5typemax(𝕊𝕢))
  init_permanence::𝕊𝕢    = round(𝕊𝕢,.4typemax(𝕊𝕢))
  synapseSampleSize::Int   = 25;      @assert synapseSampleSize>0
  θ_stimulus_activate::Int = 14;      @assert θ_stimulus_activate>0
  θ_stimulus_learn::Int    = 12;      @assert θ_stimulus_learn>0
  enable_learning::Bool    = true
  @assert θ_stimulus_learn <= θ_stimulus_activate
end
