#include("common.jl")
#include("algorithm_parameters.jl")
#include("dynamical_systems.jl")

"""
`TMState` is a named tuple of the state variables of a temporal memory.

- `A`: active neurons
- `Π`: predictive neurons

TODO
"""
mutable struct TMState
  state::NamedTuple{
    (:A, :Π, :WC, :Πₛ, :Mₛ, :ovp_Mₛ),  # Ncell, Ncell, Ncell, Nseg, Nseg, Nseg
    Tuple{CellActivity, CellActivity, CellActivity,
          BitArray{1}, BitArray{1}, Vector{Int}}
  }
end
Base.getproperty(s::TMState, name::Symbol)= name === :state ?
    getfield(s,:state) : getproperty(getfield(s,:state),name)
update_TMState!(s::TMState; Nseg,A,Π,WC,Πₛ,Mₛ,ovp_Mₛ)=
    s.state= (A=A, Π= Π, WC= WC, Πₛ= padfalse(Πₛ,Nseg),
              Mₛ= padfalse(Mₛ,Nseg), ovp_Mₛ= padfalse(ovp_Mₛ,Nseg))

"""
`TemporalMemory` learns to predict sequences of input Sparse Distributed Representations (SDRs),
usually generated by a [`SpatialPooler`](@ref).
It learns to represent each input symbol in the temporal context of the symbols that come before it in the sequence,
using the individual neurons of each minicolumn and their distal synapses.

When considering a neuron layer with proximal and distal synapses, the spatial pooler is a way to
activate and learn the proximal synapses, while the temporal memory is a way to activate and learn
the distal synapses.

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

  function TemporalMemory(params::TMParams)
    @unpack Nₙ, Nc, k = params
    Nseg_init= 0
    new(params,
        DistalSynapses(
          SparseSynapses(spzeros(𝕊𝕢,Nₙ,Nseg_init)),
          spzeros(Bool,Nₙ,Nseg_init),
          spzeros(Bool,Nₙ,Nseg_init),
          spzeros(Bool,Nseg_init,Nc),
          k),
        TMState((
          A=falses(Nₙ), Π=falses(Nₙ), WC=falses(Nₙ),
          Πₛ=falses(Nseg_init), Mₛ=falses(Nseg_init),
          ovp_Mₛ=zeros(Nseg_init)
        )))
  end
end

# Given a column activation pattern `c` (SP output), step the TM
function step!(tm::TemporalMemory, c::CellActivity)
  A,B,WC= tm_activate(tm, c)
  Π,Πₛ,Mₛ,ovp_Mₛ= tm_predict(tm, A)
  step!(tm.distalSynapses,WC, tm.previous.state,A,B,tm.params)
  update_TMState!(tm.previous,Nseg=size(tm.distalSynapses.neurSeg,2),
                  A=A,Π=Π,WC=WC,Πₛ=Πₛ,Mₛ=Mₛ,ovp_Mₛ=ovp_Mₛ)
  return A,Π, B
end

"""
`tm_activate(tm::TemporalMemory, c)` calculates

1. which minicolumns burst,
2. which neurons in the layer are activated
3. which become predictive

for minicolumn activation `c` (size `Nc`) given by the [`SpatialPooler`](@ref).
Uses also the previously predictive neurons `Π` (size `Nₙ`) from the TM's state.

# Returns

1. `a`: neuron activation (`Nₙ`)
2. `B`: bursting minicolumns (`Nc`)
3. `WC`: "winning" minicolumns (`Nc`) (have a predictive neuron)
"""
function tm_activate(tm::TemporalMemory, c)
  @unpack Nc, k = tm.params
  Π = tm.previous.Π

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
`tm_predict(tm::TemporalMemory, A)` calculates which neurons will be predictive at the next step
given the currently active neurons `a`.

# Returns

1. `Π`: predictive neurons (`Nₙ`)
2. `Πₛ`: predictive dendritic segments ('Nₛ') (caching)
3. `Mₛ`: matching dendritic segments (`Nₛ`) (learning)
4. `ovp_Mₛ`: subthreshold-matching dendritic segments (`Nₛ`) (learning)
"""
function tm_predict(tm::TemporalMemory, a)
  @unpack θ_stimulus_activate, θ_stimulus_learn = tm.params
  distal= tm.distalSynapses

  # Segment depolarization (prediction)
  Πₛ= Wd(distal)'a .> θ_stimulus_activate
  # Neuron depolarization (prediction)
  Π(Πₛ)= NS(distal)*Πₛ .> 0  # NOTE: params.θ_segment_act instead of 0
  # Sub-threshold segment stimulation sufficient for learning
  ovp_Mₛ= distal.Dd'a
  Mₛ= ovp_Mₛ .> θ_stimulus_learn
  return Π(Πₛ),Πₛ, Mₛ,ovp_Mₛ
end