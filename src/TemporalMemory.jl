module TMm
include("common.jl")
include("dynamical_systems.jl")

struct TMParams{Ncoldims}
  columnsSize::NTuple{Ncoldims,Int}
  cellϵcol::Int
  Ncol::Int
  Ncell::Int
  θ_stimulus_act::Int
  θ_stimulus_learn::Int
  θ_permanence_dist::SynapsePermanenceQuantization
  p⁺::SynapsePermanenceQuantization
  p⁻::SynapsePermanenceQuantization
  synapseSampleSize::Int
  enable_learning::Bool
end
function TMParams(columnsSize::NTuple{Ncoldims,Int}=(64,64);
                  cellϵcol=16, Ncell=0,
                  θ_permanence_dist=0.5,
                  θ_stimulus_act=8,
                  θ_stimulus_learn=6,
                  permanence⁺=0.1,
                  permanence⁻=0.08,
                  predictedSeg⁻=0.0,
                  synapseSampleSize=1,
                  max_newSynapses=12,
                  enable_learning=true
                 ) where Ncoldims
  Ncol= prod(columnsSize)
  if Ncell==0 && cellϵcol>0
    Ncell= prod(columnsSize) * cellϵcol
  elseif Ncell>0
    cellϵcol= (Ncell / Ncol)|> round
  else error("[TMParams]: Either Ncell or cellϵcol (cells per column) must be provided")
  end
  θ_stimulus_learn > θ_stimulus_act && error("[TMParams]: Stimulus threshold for
                                              learning can't be larger than activation")
  θ_permanence_dist= @>> θ_permanence_dist*typemax(SynapsePermanenceQuantization) round(SynapsePermanenceQuantization)
  p⁺= round(SynapsePermanenceQuantization, permanence⁺*typemax(SynapsePermanenceQuantization))
  p⁻= round(SynapsePermanenceQuantization, permanence⁻*typemax(SynapsePermanenceQuantization))

  TMParams{Ncoldims}(columnsSize,cellϵcol,Ncol,Ncell,
                 θ_stimulus_act,θ_stimulus_learn,θ_permanence_dist,
                 p⁺,p⁻,synapseSampleSize,
                 enable_learning)
end

mutable struct TMState
  state::NamedTuple{
    (:Π, :WC, :Πₛ, :Mₛ, :ovp_Mₛ),  # Ncell, Ncell, Nseg, Nseg, Nseg
    Tuple{CellActivity, CellActivity, BitArray{1}, BitArray{1}, Vector{Int}}
  }
end
Base.getproperty(s::TMState, name::Symbol)= name === :state ?
    getfield(s,:state) : getproperty(getfield(s,:state),name)
update_TMState!(s::TMState; Π,WC,Πₛ,Mₛ,ovp_Mₛ)=
    s.state= (Π= Π, WC= WC, Πₛ= Πₛ, Mₛ= Mₛ, ovp_Mₛ=ovp_Mₛ)

struct TemporalMemory
  params::TMParams
  distalSynapses::DistalSynapses
  previous::TMState

  function TemporalMemory(params::TMParams= TMParams();
                          Nseg_init= prod(params.columnsSize)*params.cellϵcol)
    # TODO: init TM
    distalSynapses= DistalSynapses(
        SparseSynapses((params.Ncell,),(Nseg_init,), (T,n,s)->sprand(T,n,s,2e-2)),
        sprand(Bool,params.Ncell,Nseg_init, 2e-2),
        sprand(Bool,params.Ncell,Nseg_init, 2e-2),
        sprand(Bool,Nseg_init,params.Ncol, 2e-2),
        params.cellϵcol,Xoroshiro128Plus(1))
    new(params,distalSynapses,TMState((
          Π=falses(params.Ncell), WC=falses(params.Ncell),
          Πₛ=falses(Nseg_init), Mₛ=falses(Nseg_init),
          ovp_Mₛ=zeros(Nseg_init)
        )))
  end
end

# Given a column activation pattern `c` (SP output), step the TM
function step!(tm::TemporalMemory, c::CellActivity)
  A,B,WC= tm_activation(c,tm.previous.Π,tm.params)
  step!(tm.distalSynapses,WC,tm.previous.state,A,B, tm.params)
  Π,Πₛ,Mₛ,ovp_Mₛ= tm_prediction(tm.distalSynapses,B,A,tm.params)
  update_TMState!(tm.previous,Π=Π,WC=WC,Πₛ=Πₛ,Mₛ=Mₛ,ovp_Mₛ=ovp_Mₛ)
  return A,Π
end

# Given a column activation pattern (SP output), produce the TM cell activity
# N: num of columns, M: cellPerCol
# a: [N] column activation (SP output)
# Π: [MN] predictions at t-1
function tm_activation(c,Π,params)
  k= params.cellϵcol; Ncol= length(c)
  burst()= c .& .!@percolumn(any,Π, k,Ncol)
  activate_predicted()= @percolumn(&,Π,c, k,Ncol)
  activate(A_pred, B)= (A_pred .| B')|> vec
  B= burst()
  A_pred= activate_predicted()
  return activate(A_pred,B), B, A_pred|>vec
end
# Given the TM cell activity and which columns are bursting, make TM predictions
# B: [N] bursting columns
# A: [MN] TM activation at t
# cell2seg(synapses): [MN × Nseg] cell-segment adjacency matrix
function tm_prediction(synapses,B,A, params)
  segOvp(A,D)= D'*A
  # Cell depolarization (prediction)
  Π(Πₛ)= cellXseg(synapses)*Πₛ .> 0  # NOTE: params.θ_segment_act instead of 0
  # OPTIMIZE: update connected at learning
  D= connected(synapses, params.θ_permanence_dist)
  # Overlap of connected segments
  connected_segOvp= segOvp(A,D)
  # Segment depolarization (prediction)
  Πₛ= connected_segOvp .> params.θ_stimulus_act
  # Sub-threshold segment stimulation sufficient for learning
  matching_segOvp= segOvp(A,synapses.synapses.data)
  Mₛ= matching_segOvp .> params.θ_stimulus_learn
  return Π(Πₛ),Πₛ,Mₛ,matching_segOvp
end

end#module
