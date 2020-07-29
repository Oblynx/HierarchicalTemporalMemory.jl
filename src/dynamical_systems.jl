# ## Proximal Synapses

"""
ProximalSynapses{SynapseT<:AnySynapses,ConnectedT<:AnyConnection} are the feedforward connections between
2 neuron layers, which can activate neurons and cause them to fire.

Used in the context of the [`SpatialPooler`](@ref).

# Description

The neurons of both layers are expected to form minicolumns which share the same feedforward connections.
The synapses are *binary*: they don't have a scalar weight, but either conduct (1) or not (0).
Instead, they have a *permanence* value Dₚ ∈ (0,1] and a connection threshold θ.

## Initialization

Let presynaptic (input) neuron `xᵢ` and postsynaptic (output) neuron `yᵢ`, and a topological I/O mapping
`xᵢ(yᵢ) :=` [`Hypercube`](@ref)`(yᵢ)`.
∀

## Synapse adaptation

They adapt with a hebbian learning rule.
The adaptation has a causal and an anticausal component:

- If the postsynaptic neuron fires and the presynaptic fired too, the synapse is strengthened
- If the postsynaptic neuron fires, but the presynaptic didn't, the synapse is weakened

The synaptic permanences are clipped at the boundaries of 0 and 1.

A simple implementation of the learning rule would look like this, where
z: input, a: output
```julia; results= "hidden"
learn!(Dₚ,z,a)= begin
  Dₚ[z,a]  .= (Dₚ[z,a].>0) .* (Dₚ[z,a]   .⊕ p⁺)
  Dₚ[.!z,a].= (Dₚ[z,a].>0) .* (Dₚ[.!z,a] .⊖ p⁻)
end
```

# Type parameters

They allow a dense or sparse matrix representation of the synapses

- `SynapseT`: `DenseSynapses` or `SparseSynapses`
- `ConnectedT`: `DenseConnection` or `SparseConnection`

See also: [`DistalSynapses`](@ref), [`SpatialPooler`](@ref), [`TemporalMemory`](@ref)
"""
struct ProximalSynapses{SynapseT<:AnySynapses,ConnectedT<:AnyConnection}
  Dₚ::SynapseT
  connected::ConnectedT

  """
  `ProximalSynapses(szᵢₙ,szₛₚ,synapseSparsity,γ, prob_synapse,θ_permanence)` makes an `{szᵢₙ × szₛₚ}` synapse permanence matrix
  and initializes potential synapses.

  # Algorithm

  For every output minicolumn `yᵢ`:
  - find its center in the input space `xᶜ`
  - for every input `xᵢ ∈ Hypercube(xᶜ,γ)``, draw rand `Z`
    - If `Z > prob_synapse`
      - Init permanence: rescale Z from `[0..1-θ] -> [0..1]: Z/(1-θ)``
  """
  function ProximalSynapses(szᵢₙ,szₛₚ,synapseSparsity,γ,
        prob_synapse,θ_permanence)
    # Map column coordinates to their center in the input space. Column coords FROM 1 !!!
    xᶜ(yᵢ)= floor.(Int, (yᵢ.-1) .* (szᵢₙ./szₛₚ)) .+1
    xᵢ(xᶜ)= Hypercube(xᶜ,γ,szᵢₙ)
    θ_effective()= floor(𝕊𝕢, prob_synapse*typemax(𝕊𝕢))
    out_lattice()= (c.I for c in CartesianIndices(szₛₚ))

    # Draw permanences from uniform distribution. Connections aren't very sparse (40%),
    #   so prefer a dense matrix
    permanences(::Type{SparseSynapses},xᵢ)= sprand(𝕊𝕢,length(xᵢ),1, prob_synapse)
    permanences(::Type{DenseSynapses}, xᵢ)= begin
      # Decide randomly if yᵢ ⟷ xᵢ will connect
      p= rand(𝕊𝕢range,length(xᵢ))
      p0= p .> θ_effective(); pScale= p .< θ_effective()
      fill!(view(p,p0), 𝕊𝕢(0))
      # Draw permanences from uniform distribution in 𝕊𝕢
      rand!(view(p,pScale), 𝕊𝕢range)
      return p
    end
    fillin_permanences()= begin
      Dₚ= zeros(𝕊𝕢, prod(szᵢₙ),prod(szₛₚ))
      foreach(out_lattice()) do yᵢ
        # Linear indices from hypercube
        x= @>> yᵢ xᶜ xᵢ collect map(x->c2lᵢₙ[x...])
        Dₚ[x, c2lₛₚ[yᵢ...]]= permanences(SynapseT, @> yᵢ xᶜ xᵢ)
      end
      return Dₚ
    end
    c2lᵢₙ= LinearIndices(szᵢₙ)
    c2lₛₚ= LinearIndices(szₛₚ)

    SynapseT= synapseSparsity<0.05 ? SparseSynapses : DenseSynapses
    ConnectedT= synapseSparsity<0.05 ? SparseMatrixCSC{Bool} : Matrix{Bool}
    Dₚ= fillin_permanences()
    new{SynapseT,ConnectedT}(Dₚ, Dₚ .> θ_permanence)
  end
end
Wₚ(s::ProximalSynapses)= s.connected

"""
`step!(s::ProximalSynapses, z,a, params)` adapts the proximal synapses' permanences with a hebbian learning rule on input `z`
and activation `a`. The adaptation has a causal and an anticausal component:

- If the postsynaptic neuron fires and the presynaptic fired too, the synapse is strengthened
- If the postsynaptic neuron fires, but the presynaptic didn't, the synapse is weakened

See alse: [`ProximalSynapses`](@ref)
"""
step!(s::ProximalSynapses, z,a, params)= adapt!(s.Dₚ, s, z|> vec, a|> vec, params)

# These are performance optimizations of the simple update methods described in the ProximalSynapses doc
# - minimize allocations and accesses
function adapt!(::DenseSynapses,s::ProximalSynapses, z,a, params)
  @unpack p⁺,p⁻,θ_permanence = params
  Dₚactive= @view s.Dₚ[:,a]
  activeConn=   (Dₚactive .> 0) .&   z
  inactiveConn= (Dₚactive .> 0) .& .!z
  # Learn synapse permanences according to Hebbian learning rule
  adapt_synapses!(Dₚactive, activeConn, inactiveConn, p⁺,p⁻)
  # Update cache of connected synapses
  @inbounds s.connected[:,vec(a)].= Dₚactive .> θ_permanence
end
function adapt!(::SparseSynapses,s::ProximalSynapses, z,a, params)
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach((scol,input_i)->
                    adapt_sparsesynapses!(scol,input_i, z,params.p⁺,params.p⁻),
                 s.Dₚ, a)
  # Update cache of connected synapses
  @inbounds s.connected[:,a].= s.Dₚ[:,a] .> params.θ_permanence
end

"""
`adapt_sparsesynapses!(synapses_activeCol,input_i,z,p⁺,p⁻)` updates the permanence of the given vector of synapses,
which is typically a `@view` into the nonzero elements that represent an active column of the sparse array of synapses.
The input
"""
function adapt_sparsesynapses!(synapses_activeCol,input_i, z,p⁺,p⁻)
  @inbounds z_i= z[input_i]
  adapt_synapses!(synapses_activeCol, z_i, .!z_i, p⁺,p⁻)
end

adapt_synapses!(synapses, activeConn, inactiveConn, p⁺,p⁻)= (
  @inbounds synapses.= activeConn .* (synapses .⊕ p⁺) .+
                     inactiveConn .* (synapses .⊖ p⁻)
)



# ## Distal synapses for the TM
# (assume the same learning rule governs all types of distal synapses)

"""
`DistalSynapses` are lateral connections within a neuron layer that attach to the dendrites of neurons,
not directly to the soma (neuron's center), and can therefore **depolarize** neurons but *can't activate them.*
Compare with [`ProximalSynapses`](@ref).

Used in the context of the [`TemporalMemory`](@ref).

# Description

### Synapses

Neurons have multiple signal integration zones: the soma, proximal dendrites, apical dendrites.
Signals are routed to the proximal dendrites through *distal synapses*.
This type defines both the synapses themselves and the neuron's dendrites.
The synapses themselves, like the [`ProximalSynapses`](@ref), are binary connections without weights.
They have a **permanence value**, and above a threshold they are connected.

The synapses can be represented as an adjacency matrix of dimensions `Nₙ × Nₛ`:
presynaptic neurons -> postsynaptic dendritic segments.
This matrix is derived from the synapse permanence matrix ``D_d ∈ \\mathit{𝕊𝕢}^{Nₙ × Nₛ}``,
which is **sparse** (eg 0.5% synapses).
This affects the implementation of all low-level operations.

### Dendritic segments

Neurons have multiple dendritic segments carrying the distal synapses, each sufficient to depolarize the neuron (make it predictive).
The neuron/segment adjacency matrix `neurSeg` (aka `NS`) also has dimensions `Nₙ × Nₛ`.

## Learning

Instead of being randomly initialized like the proximal synapses, distal synapses and dendrite segments are grown on demand:
when minicolumns can't predict their activation and burst, they trigger a growth process.

The synaptic permanence itself adapts similar to the proximal synapses: synapses that correctly predict are increased,
synapses that incorrectly predict are decreased.
However it's a bit more complicated to define the successful distal syapses than the proximal synapses.
"Winning segments" `WS` will adapt their synapses towards "winning neurons" `WN`.
Since synapses are considered directional, neurons are always presynaptic and segments postsynaptic.

Winning segments are those that were predicted and then activated.
Also, for every bursting minicolumn the dendrite that best "matches" the input will become winner.
If there is no sufficiently matching dendrite, a new onw will grow on the neuron that has the fewest.

Winning neurons are again those that were predicted and then activated.
Among the bursting minicolumns, the neurons bearing the winning segments are the winners.
Both definitions of winners are aligned with establishing a causal relationship: prediction -> activation.

New synapses grow from `WS` towards a random sample of `WN` at every step.
Strongly matching segments have a lower chance to grow new synapses than weakly matching segments.

!!! note
    Adding new synapses at random indices of `Dd::SparseMatrixCSC` is a performance bottleneck, because it involves
    moving the matrix's existing data. An implementation of `SparseMatrixCSC` with hashmaps could help,
    such as [SimpleSparseArrays.jl](https://github.com/jw3126/SimpleSparseArrays.jl/)

## Caching

The state of the DistalSynapses is determined by the 2 matrices ``D_d, \\mathit{NS}``.
A few extra matrices are filled in over the evolution of the distal synapses to accelerate the computations:
- `connected` caches `Dd > θ_permanence`
- `segCol` caches the segment - column map (aka `SC`)
"""
mutable struct DistalSynapses
  # synapse permanence
  Dd::SparseSynapses                     # Nn × Nseg
  # neurons - segments
  neurSeg::SparseMatrixCSC{Bool,Int}     # Nn × Nseg
  # caches
  connected::SparseMatrixCSC{Bool,Int}   # Nn × Nsed
  segCol::SparseMatrixCSC{Bool,Int}      # Nseg × Ncol
  k::Int
  params::DistalSynapseParams
end
# friendly names for the matrices
NS(s::DistalSynapses)= s.neurSeg
SC(s::DistalSynapses)= s.segCol
Wd(s::DistalSynapses)= s.connected
Nₛ(s::DistalSynapses)= size(s.neurSeg,2)

# segments belonging to columns
col2seg(s::DistalSynapses,col::Int)= SC(s)[:,col].nzind
col2seg(s::DistalSynapses,col)= rowvals(SC(s)[:,col])
# neurons belonging to column
col2cell(col,k)= (col-1)*k+1 : col*k
# column for each cell
cell2col(cells,k)= @. (cells-1) ÷ k + 1

# Adapt distal synapses based on TM state at t-1 and current cell/column activity
# A: [Ncell] cell activity
# B: [Ncol] column activity
# WC: [Ncell] current winner cells from predicted columns; add from bursting columns
function step!(s::DistalSynapses, pWN,WS, α, pα,pMₛ,povp_Mₛ)
  @unpack p⁺,p⁻,LTD_p⁻,θ_permanence = s.params
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach((scol,cell_i)->
                    adapt_sparsesynapses!(scol,cell_i, pα, p⁺,p⁻),
                 s.Dd, WS)
  # Decay "matching" synapses that didn't result in an active neuron
  sparse_foreach((scol,cell_i)->
                    adapt_sparsesynapses!(scol,cell_i, .!pα,zero(𝕊𝕢),LTD_p⁻),
                 s.Dd, decayS(s,pMₛ,α))
  growsynapses!(s, pWN,WS, povp_Mₛ)
  # Update cache of connected synapses
  #@inbounds s.connected[:,WS].= s.synapses[:,WS] .> params.θ_permanence
  s.connected= s.Dd .> θ_permanence
end


"""
`decayS(s::DistalSynapses,pMₛ,α)` are the dendritic segments that should decay according to LTD (long term depression).
It's the segments that at the previous moment had enough potential synapses with active neurons to "match" the input (`pMₛ`),
but didn't contribute to their neuron firing at this moment (they didn't activate strongly enough to depolarize it).
"""
decayS(s::DistalSynapses,pMₛ,α)= (@> pMₛ padfalse(Nₛ(s))) .& (NS(s)'*(.!α))

"""
`calculate_WS!(pΠₛ,povp_Mₛ, α,B)` finds the winning segments, growing new ones where necessary.
"""
function calculate_WS!(s::DistalSynapses, pΠₛ,povp_Mₛ, α,B)
  WS_pred= WS_predictedcol(s,pΠₛ,α)
  WS_burst= WS_burstcol!(s,B,povp_Mₛ)
  WS= (@> WS_pred padfalse(Nₛ(s))) .| WS_burst
  return (WS, WS_burst)
end

## Calculate the winning segments WS

# If a cell was previously depolarized and now becomes active, the segments that caused
# the depolarization are winning.
WS_predictedcol(s::DistalSynapses,pΠₛ,α)= pΠₛ .& (NS(s)'α .>0)
# If a cell is part of a bursting column, the segment in the column with the highest
# overlap wins.
# Foreach bursting col, find the best matching segment or grow one if needed
WS_burstcol!(s::DistalSynapses,B, povp_Mₛ)= begin
  burstingCols= findall(B)
  maxsegs= Vector{Option{Int}}(undef,length(burstingCols))
  map!(col->bestmatch(s,col,povp_Mₛ), maxsegs, burstingCols)
  growseg!(s, maxsegs, burstingCols)
  @> maxsegs bitarray(Nₛ(s))
end

# Best matching segment for column - or `nothing`
"""
`bestmatch(s::DistalSynapses,col, povp_Mₛ)` finds the best-matching segment in a column,
as long as its overlap with the input (its activation) is > θ_stimulus_learn.
Otherwise, returns `nothing`.
"""
function bestmatch(s::DistalSynapses,col, povp_Mₛ)
  segs= col2seg(s,col)
  isempty(segs) && return nothing   # If there's no existing segments in the column
  m,i= findmax(povp_Mₛ[segs])
  m > s.params.θ_stimulus_learn ? segs[i] : nothing
end

"""
`growsynapses!(s::DistalSynapses, pWN::CellActivity,WS, povp_Mₛ)` adds synapses between winning dendrites (`WS`)
and a random sample of previously winning neurons (`pWN`).

For each dendrite, target neurons are selected among `pWN` with probability to pick each neuron
determined by ``\\frac{ (\\mathit{synapseSampleSize} - \\mathit{prev_Overlap} }{ length(\\mathit{pWN}) }``
(Bernoulli sampling)

This involves inserting new elements in random places of a `SparseMatrixCSC` and is the algorithm's performance bottleneck.
- TODO: try replacing CSC with a Dict implementation of sparse matrices.
"""
function growsynapses!(s::DistalSynapses, pWN::CellActivity,WS, povp_Mₛ)
  @unpack synapseSampleSize, init_permanence = s.params
  _growsynapses!(pWN)= begin
    Nnewsyn(ovp)= max(0,synapseSampleSize - ovp)
    # probability to sample each new synapse
    psampling_newsyn= min.(1.0, Nnewsyn.(padfalse(povp_Mₛ,Nₛ(s))[WS]) ./ length(pWN))
    # preallocate storage for sampling
    selectedWN= similar(pWN)
    foreach(Truesof(WS), psampling_newsyn) do seg_i, p
      # Bernoulli sampling from WN with mean sample size == Nnewsyn
      randsubseq!(selectedWN,pWN,p)
      # Grow new synapses (percolumn manual | setindex percolumn | setindex WN,WS,sparse_V)
      s.Dd[selectedWN, seg_i].= init_permanence
    end
  end

  pWN= findall(pWN)
  !isempty(pWN) && _growsynapses!(pWN)
end

"""
`leastusedcell(s::DistalSynapses,col)` finds the neuron of a minicolumn with the fewest dendrites.
- TODO: try Memoize.jl !
"""
function leastusedcell(s::DistalSynapses,col)
  neuronsWithSegs= NS(s)[:,col2seg(s,col)].rowval|> countmap_empty
  neuronsWithoutSegs= setdiff(col2cell(col,s.k), neuronsWithSegs|> keys)
  # If there's no neurons without dendrites, return the one with the fewest
  isempty(neuronsWithoutSegs) ?
      findmin(neuronsWithSegs)[2] : rand(neuronsWithoutSegs)
end

# OPTIMIZE add many segments together for efficiency?
"""
`growseg!(s::DistalSynapses,WS_col::Vector{Option{Int}},burstingcolidx)` grows 1 new segment for each column with `nothing`
as winning segment and replaces `nothing` with it. It resizes all the `DistalSynapses` matrices to append
new dendritic segments. Foreach bursting minicolumn without a winning segment,
the neuron to grow the segment is the one with the fewest segments.
"""
function growseg!(s::DistalSynapses,WS_col::Vector{Option{Int}},burstingcolidx)
  neuronsToGrow= map(col-> leastusedcell(s,col), burstingcolidx[isnothing.(WS_col)])
  columnsToGrow= cell2col(neuronsToGrow,s.k)
  Ncell= size(s.Dd,1); Ncol= size(s.segCol,2)
  Nseg_before= Nₛ(s)
  Nseggrow= length(neuronsToGrow)  # grow 1 seg per cell
  _grow_synapse_matrices!(s,columnsToGrow,neuronsToGrow,Nseggrow)
  # Replace in maxsegs, `nothing` with something :-)
  WS_col[isnothing.(WS_col)].= Nseg_before.+(1:Nseggrow)
end
function _grow_synapse_matrices!(s::DistalSynapses,columnsToGrow,neuronsToGrow,Nseggrow)
  s.Dd= hcat!!(s.Dd, Nseggrow)
  s.neurSeg= hcat!!(s.neurSeg, neuronsToGrow, trues(Nseggrow))
  s.connected= hcat!!(s.connected, neuronsToGrow, falses(Nseggrow))
  s.segCol= vcat!!(s.segCol, columnsToGrow, trues(Nseggrow))
end

"""
`countmap_empty(x)` [Dict] Count the frequency of occurence for each element in x
"""
countmap_empty(x)= isempty(x) ? x : countmap(x)