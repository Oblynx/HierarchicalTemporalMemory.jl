"""
`SPParams{Nin,Nsp}` holds the algorithm parameters for a spatial pooler with nomenclature
similar to [source](https://www.frontiersin.org/articles/10.3389/fncom.2017.00111/full)

The dimension parameters are problem-specific and should be the first to be specified.

The tuning parameters have sensible defaults, which should be .
All gated features are enabled by default.

# Parameters

## Dimensions
- `szᵢₙ = (32,32)`: input dimensions
- `szₛₚ = (32,32)`: output dimensions
- `γ = 6`: receptive field radius (how large an input area an output minicolumn maps to)

## Algorithm tuning
- `s = .02`: average output sparsity
- `prob_synapse = .5`: probability for each element of the `szᵢₙ × szₛₚ` space to be a synapse.
  Elements that roll below this value don't form a synapse and don't get a permanence value.
  If this is very low, the proximal synapses matrix can become sparse.
- `θ_permanence01 = .5`: synapse permanence connection threshold
- `p⁺_01 = .1 , p⁻_01 = .02`: synapse permanence adaptation rate (see [`ProximalSynapses`](@ref))
- `θ_stimulus_activate = 1`: minicolumn absolute activation threshold
- `Tboost = 200.0`: boosting mechanism's moving average filter period
- `β = 1.0`: boosting strength

## Feature gates
- `enable_local_inhibit = true`
- `enable_learning = true`
- `enable_boosting = true`
"""
@with_kw struct SPParams{Nin,Nsp}
  # dimensions
  szᵢₙ::Union{NTuple{Nin,Int},Int}     = (32,32); @assert all(szᵢₙ.>0)
  szₛₚ::Union{NTuple{Nsp,Int},Int}     = (50,50); @assert all(szₛₚ.>0)
  γ::Int                    = 6;       @assert γ>0

  # tuning
  s::Float32                = .02;     @assert s>0
  prob_synapse::Float32     = .5;      @assert 0<=prob_synapse<=1
  θ_permanence01::Float32   = .5;      @assert 0<=θ_permanence01<=1
  p⁺_01::Float32            = .1;      @assert 0<=p⁺_01<=1
  p⁻_01::Float32            = .02;     @assert 0<=p⁻_01<=1
  θ_permanence::𝕊𝕢        = round(𝕊𝕢, θ_permanence01*typemax(𝕊𝕢))
  p⁺::𝕊𝕢                  = round(𝕊𝕢, p⁺_01*typemax(𝕊𝕢))
  p⁻::𝕊𝕢                  = round(𝕊𝕢, p⁻_01*typemax(𝕊𝕢))
  θ_stimulus_activate::Int  = 1;       @assert θ_stimulus_activate>=0
  Tboost::Float32           = 200;     @assert Tboost>0
  β::Float32                = 1;       @assert β>0

  # feature gates
  enable_local_inhibit::Bool= true
  enable_learning::Bool     = true
  enable_boosting::Bool     = true
  @assert zero(𝕊𝕢)<=θ_permanence<=typemax(𝕊𝕢)
  @assert zero(𝕊𝕢)<=p⁺<=typemax(𝕊𝕢)
  @assert zero(𝕊𝕢)<=p⁻<=typemax(𝕊𝕢)
end

"""
`TMParams` holds the algorithm parameters for a Temporal Memory with nomenclature
similar to [source]()

## Dimensions
- `Nc = 2500`: number of columns
- `k = 10`: cells per column
- `Nₙ = k Nc` neurons in layer. The `Nₛ` number of dendritic segments
  is variable

## Tuning
- `p⁺_01 = .12 , p⁻_01 = .04 ∈ [0,1]`: synapse permanence adaptation rate (see [`ProximalSynapses`](@ref))
- `LTD_p⁻_01 = .002 ∈ [0,1]`: synapse long term depression rate
- `θ_permanence = .5*typemax(𝕊𝕢) ∈ 𝕊𝕢`: synapse permanence connection threshold
- `init_permanence = .4*typemax(𝕊𝕢) ∈ 𝕊𝕢`: permanence of a newly-grown synapse
- `synapseSampleSize = 25 ∈ ℕ`: target number of matching synapses per dendrite.
  Represents how many bits the dendrite targets to recognize the input.
  Dendrites with fewer synapses matching the input might grow new synapses.
- `θ_stimulus_activate = 14 ∈ ℕ`: number of matching synapses needed to depolarize the dendrite
- `θ_stimulus_learn = 12 ∈ ℕ`: number of matching synapses that are insufficient to depolarize the
  dendrite, but sufficient to trigger learning. `θ_stimulus_learn <= θ_stimulus_activate`

## Feature gates
- `enable_learning = true`
"""
@with_kw struct TMParams
  # dimensions
  Nc::Int                  = 2500;    @assert Nc>0
  k::Int                   = 10;      @assert k>0
  Nₙ::Int                  = k*Nc;    @assert Nₙ>0

  # tuning
  p⁺_01::Float32           = .12;     @assert 0<=p⁺_01<=1
  p⁻_01::Float32           = .04;     @assert 0<=p⁻_01<=1
  LTD_p⁻_01::Float32       = .002;    @assert 0<=LTD_p⁻_01<=1
  p⁺::𝕊𝕢                 = round(𝕊𝕢,p⁺_01*typemax(𝕊𝕢))
  p⁻::𝕊𝕢                 = round(𝕊𝕢,p⁻_01*typemax(𝕊𝕢))
  LTD_p⁻::𝕊𝕢             = round(𝕊𝕢,LTD_p⁻_01*typemax(𝕊𝕢))
  θ_permanence::𝕊𝕢       = round(𝕊𝕢,.5typemax(𝕊𝕢))
  init_permanence::𝕊𝕢    = round(𝕊𝕢,.4typemax(𝕊𝕢))
  synapseSampleSize::Int   = 25;      @assert synapseSampleSize>0
  θ_stimulus_activate::Int = 14;      @assert θ_stimulus_activate>0
  θ_stimulus_learn::Int    = 12;      @assert 0 < θ_stimulus_learn <= θ_stimulus_activate

  # feature gates
  enable_learning::Bool    = true
end

# Created from TMParams
@with_kw struct DistalSynapseParams
  p⁺::𝕊𝕢                 = round(𝕊𝕢,p⁺_01*typemax(𝕊𝕢))
  p⁻::𝕊𝕢                 = round(𝕊𝕢,p⁻_01*typemax(𝕊𝕢))
  LTD_p⁻::𝕊𝕢             = round(𝕊𝕢,LTD_p⁻_01*typemax(𝕊𝕢))
  θ_permanence::𝕊𝕢       = round(𝕊𝕢,.5typemax(𝕊𝕢))
  init_permanence::𝕊𝕢    = round(𝕊𝕢,.4typemax(𝕊𝕢))
  synapseSampleSize::Int   = 25;      @assert synapseSampleSize>0
  θ_stimulus_learn::Int    = 12;      @assert 0 < θ_stimulus_learn
end
DistalSynapseParams(tmParams::TMParams)= begin
  @unpack p⁺, p⁻, LTD_p⁻, θ_permanence,
      init_permanence, synapseSampleSize, θ_stimulus_learn = tmParams
  DistalSynapseParams(p⁺, p⁻, LTD_p⁻, θ_permanence,
      init_permanence, synapseSampleSize, θ_stimulus_learn)
end
