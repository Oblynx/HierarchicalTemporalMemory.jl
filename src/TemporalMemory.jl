module TMm
include("common.jl")
include("dynamical_systems.jl")

struct TMParams{Ncol}
  columnsSize::NTuple{Ncol,Int}
  cellϵcol::Int
  Ncell::Int
  Nseg::Int
  θ_stimulus_act::Int
  θ_stimulus_learn::Int
  θ_permanence_dist::SynapsePermanenceQuantization
  p⁺::SynapsePermanenceQuantization
  p⁻::SynapsePermanenceQuantization
  synapseSampleSize::Int
  enable_learning::Int
end
function TMParams(columnsSize::NTuple{Ncol,Int}=(64,64);
                  cellϵcol=16, Ncell=0, Nseg=0,
                  θ_permanence_dist=0.5,
                  θ_stimulus_act=8,
                  θ_stimulus_learn=6,
                  permanence⁺=0.1,
                  permanence⁻=0.08,
                  predictedSeg⁻=0.0,
                  synapseSampleSize=1,
                  max_newSynapses=12,
                  enable_learning=true
                 ) where Ncol
  if Ncell==0 && cellϵcol>0
    Ncell= prod(columnsSize) * cellϵcol
  elseif Ncell>0
    cellϵcol= (Ncell / prod(columnsSize))|> round
  else error("[TMParams]: Either Ncell or cellϵcol (cells per column) must be provided")
  end
  θ_stimulus_learn > θ_stimulus_act && error("[TMParams]: Stimulus threshold for
                                              learning can't be larger than activation")
  Nseg= floor(Nseg/Ncell) * Ncell
  θ_permanence_dist= @>> θ_permanence_dist*typemax(SynapsePermanenceQuantization) round(SynapsePermanenceQuantization)
  p⁺= round(SynapsePermanenceQuantization, permanence⁺*typemax(SynapsePermanenceQuantization))
  p⁻= round(SynapsePermanenceQuantization, permanence⁻*typemax(SynapsePermanenceQuantization))

  TMParams{Ncol}(columnsSize,cellϵcol,Ncell,Nseg,
                 θ_stimulus_act,θ_stimulus_learn,θ_permanence_dist,
                 p⁺,p⁻,synapseSampleSize,
                 enable_learning)
end

struct TemporalMemory
  params::TMParams
  distalSynapses::DistalSynapses
  Π::CellActivity

  function TemporalMemory(params::TMParams= TMParams())
    distalSynapses= DistalSynapses(
        SparseSynapses((params.Ncell,),(params.Nseg,), (T,n,s)->sprand(T,n,s,2e-2)),
        sprand(Bool,params.Ncell,params.Nseg, 2e-2))
    new(params,distalSynapses,falses(params.Ncell))
  end
end

# Given a column activation pattern `c` (SP output), step the TM
function step!(tm::TemporalMemory, c::CellActivity)
  a,π= tm_activation(tm.distalSynapses, c,tm.Π, tm.params)
  if tm.params.enable_learning
    step!(tm.distalSynapses,a,c, tm.params)
  end
  return a,π
end

# Given a column activation pattern (SP output), produce the TM cell activity & prediction
# N: num of columns, M: cellPerCol
# W: [N] column activation (SP output)
# Π: [MN] predictions at t-1
# cell2seg(synapses): [MN × Nseg] cell-segment adjacency matrix
function tm_activation(synapses,W,Π,params)
  k= params.cellϵcol; Ncol= length(W)
  π_s(a,D)= D'*a .> params.θ_stimulus_act
  π(a,D)= cellXseg(synapses)*π_s(a,D) .> 0  # NOTE: params.θ_segment_act instead of 0
  activate(B)= (@percolumn(&,Π,W, k,Ncol) .| B')|> vec
  B()= W .& .!@percolumn(any,Π, k,Ncol)

  D= connected(synapses, params.θ_permanence_dist)
  a= activate(B())
  return a,π(a,D)
end

end#module
