#include("common.jl")
#include("algorithm_parameters.jl")
#include("dynamical_systems.jl")

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

struct TemporalMemory
  params::TMParams
  distalSynapses::DistalSynapses
  previous::TMState

  function TemporalMemory(params::TMParams)
    @unpack Nₙ, Nc, cellϵcol = params
    Nseg_init= 0
    new(params,
        DistalSynapses(
          SparseSynapses(spzeros(𝕊𝕢,Nₙ,Nseg_init)),
          spzeros(Bool,Nₙ,Nseg_init),
          spzeros(Bool,Nₙ,Nseg_init),
          spzeros(Bool,Nseg_init,Nc),
          cellϵcol),
        TMState((
          A=falses(Nₙ), Π=falses(Nₙ), WC=falses(Nₙ),
          Πₛ=falses(Nseg_init), Mₛ=falses(Nseg_init),
          ovp_Mₛ=zeros(Nseg_init)
        )))
  end
end

# Given a column activation pattern `c` (SP output), step the TM
function step!(tm::TemporalMemory, c::CellActivity)
  A,B,WC= tm_activation(c,tm.previous.Π,tm.params)
  Π,Πₛ,Mₛ,ovp_Mₛ= tm_prediction(tm.distalSynapses,A,tm.params)
  step!(tm.distalSynapses,WC, tm.previous.state,A,B,tm.params)
  update_TMState!(tm.previous,Nseg=size(tm.distalSynapses.cellSeg,2),
                  A=A,Π=Π,WC=WC,Πₛ=Πₛ,Mₛ=Mₛ,ovp_Mₛ=ovp_Mₛ)
  return A,Π, B
end

# Given a column activation pattern (SP output), produce the TM cell activity
# N: num of columns, M: cellPerCol
# a: [N] column activation (SP output)
# Π: [MN] predictions at t-1
function tm_activation(c,Π,params)
  k= params.cellϵcol; Ncol= length(c)
  burst()= c .& .!@percolumn(any,Π, k)
  activate_predicted()= @percolumn(&,Π,c, k)
  activate(A_pred, B)= (A_pred .| B')|> vec
  B= burst()
  A_pred= activate_predicted()
  return activate(A_pred,B), B, A_pred|>vec
end
# Given the TM cell activity and which columns are bursting, make TM predictions
# B: [N] bursting columns
# A: [MN] TM activation at t
# cell2seg(synapses): [MN × Nseg] cell-segment adjacency matrix
function tm_prediction(distalSynapses,A, params)
  @unpack θ_stimulus_activate, θ_stimulus_learn = params
  segOvp(A,D)= D'*A
  # Cell depolarization (prediction)
  Π(Πₛ)= cellXseg(distalSynapses)*Πₛ .> 0  # NOTE: params.θ_segment_act instead of 0
  # OPTIMIZE: update connected at learning
  D= connected(distalSynapses)
  # Overlap of connected segments
  connected_segOvp= segOvp(A,D)
  # Segment depolarization (prediction)
  Πₛ= connected_segOvp .> θ_stimulus_activate
  # Sub-threshold segment stimulation sufficient for learning
  matching_segOvp= segOvp(A,distalSynapses.synapses)
  Mₛ= matching_segOvp .> θ_stimulus_learn
  return Π(Πₛ),Πₛ,Mₛ,matching_segOvp
end
