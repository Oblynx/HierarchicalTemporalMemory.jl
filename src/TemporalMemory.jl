#include("common.jl")
#include("algorithm_parameters.jl")
#include("dynamical_systems.jl")

"""
`TMState` is a named tuple of the state variables of a temporal memory.

- `α`: active neurons
- `Π`: predictive neurons
- `WN`: winning neurons
- `Πₛ`: predictive dendritic segments (to calculate winning segments)
- `Mₛ`: matching dendritic segments (didn't receive enough input to activate, but enough to learn)
- `ovp_Mₛ`:
"""
mutable struct TMState
  state::NamedTuple{
    (:α, :Π, :WN, :Πₛ, :Mₛ, :ovp_Mₛ),  # Ncell, Ncell, Ncell, Nseg, Nseg, Nseg
    Tuple{CellActivity, CellActivity, CellActivity,
          BitArray{1}, BitArray{1}, Vector{Int}}
  }
  init_Nseg::Int
end
TMState(Nₙ, Nseg)= TMState((
  α=falses(Nₙ), Π=falses(Nₙ), WN=falses(Nₙ),
  Πₛ=falses(Nseg), Mₛ=falses(Nseg),
  ovp_Mₛ=zeros(Nseg)
), Nseg)
Base.getproperty(s::TMState, name::Symbol)= name === :state ?
    getfield(s,:state) : getproperty(getfield(s,:state),name)
update_TMState!(s::TMState; Nseg,α,Π,WN,Πₛ,Mₛ,ovp_Mₛ)=
    s.state= (α=α, Π= Π, WN= WN, Πₛ= padfalse(Πₛ,Nseg),
              Mₛ= padfalse(Mₛ,Nseg), ovp_Mₛ= padfalse(ovp_Mₛ,Nseg))
reset!(s::TMState)= begin
  Nₙ= length(s.α);
  update_TMState!(s, Nseg=s.Nseg, α=falses(Nₙ), Π=falses(Nₙ), WN=falses(Nₙ),
    Πₛ=falses(s.Nseg), Mₛ=falses(s.Nseg), ovp_Mₛ=zeros(s.Nseg))
end

"""
    TemporalMemory(params::TMParams; recurrent= true, distal_input_size=0)

`TemporalMemory` learns to predict sequences of input Sparse Distributed Representations (SDRs),
usually generated by a [`SpatialPooler`](@ref).
It learns to represent each input symbol in the temporal context of the symbols that come before it in the sequence,
using the individual neurons of each minicolumn and their distal synapses.

When considering a neuron layer with proximal and distal synapses, the spatial pooler is a way to
activate and learn the proximal synapses, while the temporal memory is a way to activate and learn
the distal synapses.

Parameters:

- `params`: [`TMParams`](@ref) defining the layer size and algorithm constants
- `recurrent`: presence of recurrent distal connections between the layer's neurons
- `distal_input_size`: the number of presynaptic neurons for each layer with incoming distal connections (apart from same layer's neurons)

## High-order predictions and Ambiguity

The [neurons-thousand-synapses paper](https://www.frontiersin.org/articles/10.3389/fncir.2016.00023/full) describes the
Temporal Memory's properties, and especially the ability to
- make "high-order" predictions, based on previous inputs potentially going far back in time
- represent ambiguity in the form of simultaneous predictions

For more information see figures 2,3 in the paper.

# TM activation

Overview of the temporal memory's process:

1. Activate neurons (fire, proximal synapses)
2. Predict neurons (depolarize, distal/apical synapses)
3. Learn distal/apical synapses:
    - adapt existing synapses
    - create new synapses/dendrites

## Activation

An SDR input activates some minicolumns of the neuron layer.
If some neurons in the minicolum were predicted at the previous step, they activate faster than the rest and inhibit them.
If no neuron was predicted, all the neurons fire (minicolumn bursting).

TODO

---
See also: [`TMParams`](@ref) for parameter and symbol description, [`DistalSynapses`](@ref), [`TMState`](@ref)
"""
struct TemporalMemory
  params::TMParams
  distalSynapses::DistalSynapses
  previous::TMState
  recurrent::Bool
end
function TemporalMemory(params::TMParams; recurrent= true, distal_input_size=0)
  @unpack Nₙ, Nc, k = params
  distal_input_size= Int(distal_input_size)
  @assert recurrent || distal_input_size > 0 "At least 1 of recurrent or external input connections are needed"

  # NOTE: it's not possible to have independent distal synapses for each presynaptic input,
  # because we need a single address space for postsynaptic segments. Otherwise,
  # it would be impossible to mix signals from multiple sources.
  N_presynaptic= recurrent ? Nₙ + distal_input_size : distal_input_size
  Nseg_init= 0

  TemporalMemory(params,
      DistalSynapses(N_presynaptic, Nc, k;
        Nseg_init= Nseg_init, params= DistalSynapseParams(params)),
      TMState(Nₙ,Nseg_init),
      recurrent)
end

Nₙ(tm::TemporalMemory)= tm.params.Nₙ
reset!(tm::TemporalMemory)= begin
  reset!(tm.distalSynapses)
  reset!(tm.previous)
end

"""
`step!(tm::TemporalMemory, c, distal_input=[])` evolves the Temporal Memory to the next timestep
given the minicolumn activations and any distal input.
Returns the state of the region's neurons: active, predictive, bursting (minicolumns)

See also: [`tm_activate`](@ref), [`tm_predict`](@ref)
"""
# Given a column activation pattern `c` (SP output), step the TM
function step!(tm::TemporalMemory, c, distal_input=falses(0))
  s= tm.distalSynapses; p= tm.previous

  α, B, WN= tm_activate(tm, c, p.Π)
  # If recurrent, concatenate distal input activity with this layer's activity
  distal_input= tm.recurrent ? [α;distal_input] : distal_input
  Π, Πₛ, Mₛ, ovp_Mₛ= tm_predict(tm, distal_input)

  # Learn
  WS, WS_burst= calculate_WS!(s, p.Πₛ,p.ovp_Mₛ,α,B)
  # Update winner neurons with entries from bursting columns
  WN[NS(s)*WS_burst .> 0].= true
  step!(s, p.WN,WS, α, p.α,p.Mₛ,p.ovp_Mₛ)
  update_TMState!(p, Nseg=Nₛ(s),
                  α=α, Π=Π, WN=WN, Πₛ=Πₛ, Mₛ=Mₛ, ovp_Mₛ=ovp_Mₛ)
  return (
    active= α,
    predictive= Π,
    bursting= B
  )
end

"""
Active and predictive cells given the minicolumn activations and any distal input.

See also: [`tm_activate`](@ref), [`tm_predict`](@ref)
"""
(tm::TemporalMemory)(c, distal_input=falses(0))= begin
  α= tm_activate(tm,c,tm.previous.Π)[1]
  # If recurrent, concatenate distal input activity with this layer's activity
  distal_input= tm.recurrent ? [α;distal_input] : distal_input
  (
    active= α,
    predictive= tm_predict(tm,distal_input)[1]
  )
end

"""
`tm_activate(tm::TemporalMemory, c, Π)` calculates

1. which minicolumns burst,
2. which neurons in the layer are activated
3. which become predictive

for minicolumn activation `c` (size `Nc`) given by the [`SpatialPooler`](@ref)
and the previously predictive neurons `Π` (size `Nₙ`).

# Returns

1. `a`: neuron activation (`Nₙ`)
2. `B`: bursting minicolumns (`Nc`)
3. `WN`: "winning" neurons (`Nₙ`)

See also: [`tm_predict`](@ref), [`DistalSynapses`](@ref)
"""
function tm_activate(tm::TemporalMemory, c, Π)
  @unpack Nc, k = tm.params

  # bursting minicolumns (Nc)
  burst(c,Π)= c .& .!@percolumn(any, Π, k)
  # minicolumns with a predictive neuron (k × Nc)
  predicted(c,Π)= @percolumn(&,Π,c, k)
  # activation for the whole layer given the predicted/bursting neurons
  activate(A_pred, B)= (A_pred .| B')|> vec
  # cache parts of the output because they're used 2 times
  B= burst(c,Π)           # Nc
  A_pred= predicted(c,Π)  # k × Nc
  return activate(A_pred,B), B, A_pred|>vec
end

"""
`tm_predict(tm::TemporalMemory, α)` calculates which neurons will be predictive at the next step
given the currently active neurons + distal input `α`.
`size(a)` must match the presynaptic length of `tm.distalSynapses`.

# Returns

1. `Π`: predictive neurons (`Nₙ`)
2. `Πₛ`: predictive dendritic segments ('Nₛ') (caching)
3. `Mₛ`: matching dendritic segments (`Nₛ`) (learning)
4. `ovp_Mₛ`: subthreshold-matching dendritic segments (`Nₛ`) (learning)
"""
function tm_predict(tm::TemporalMemory, α::CellActivity)
  @unpack θ_stimulus_activate, θ_stimulus_learn = tm.params
  distal= tm.distalSynapses

  # Segment depolarization (prediction)
  Πₛ= Wd(distal)'α .> θ_stimulus_activate
  # Neuron depolarization (prediction)
  Π(Πₛ)= NS(distal)*Πₛ .> 0  # NOTE: params.θ_segment_act instead of 0
  # Sub-threshold segment stimulation sufficient for learning
  ovp_Mₛ= distal.Dd'α
  Mₛ= ovp_Mₛ .> θ_stimulus_learn
  return Π(Πₛ),Πₛ, Mₛ,ovp_Mₛ
end