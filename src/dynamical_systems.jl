# ## Inhibition Radius

"""
The inhibition radius of a Spatial Pooler's columns is a dynamical system that evolves
under the influence of other elements of the Spatial Pooler. It provides an init
(constructor) and a step! function.
"""
mutable struct InhibitionRadius <:AbstractFloat
  φ::Float32
  InhibitionRadius(γ,prob_synapse,szᵢₙ,szₛₚ,enable_local_inhibit=true)=
      enable_local_inhibit ?
        new(simplified_update_φ(γ,prob_synapse,szᵢₙ,szₛₚ)) :
        new(maximum(szₛₚ)+1)
end

function step!(s::InhibitionRadius, params)
  @unpack γ,prob_synapse,szᵢₙ,szₛₚ,enable_local_inhibit = params
  if enable_local_inhibit
    s.φ= simplified_update_φ(γ,prob_synapse,szᵢₙ,szₛₚ)
  end
end

simplified_update_φ(γ,prob_synapse,szᵢₙ,szₛₚ)= begin
  mean_receptiveFieldSpan()= (γ*2+0.5)*prob_synapse
  receptiveFieldSpan_yspace()= (mean_receptiveFieldSpan()*mean(szₛₚ./szᵢₙ)-1)/2
  max(receptiveFieldSpan_yspace(), 1)
end

# This implementation follows the SP paper description and NUPIC, but seems too complex
#   for no reason. Replace with a static inhibition radius instead
#nupic_update_φ(γ,prob_synapse,szᵢₙ,szₛₚ,s::InhibitionRadius)= begin
#  mean_receptiveFieldSpan()::Float32= mapslices(receptiveFieldSpan, W, dims=1)|> mean
#  receptiveFieldSpan_yspace()= (mean_receptiveFieldSpan()*mean(szₛₚ./szᵢₙ)-1)/2
#  max(receptiveFieldSpan_yspace(), 1)
#end
#receptiveFieldSpan(colinputs,s::InhibitionRadius)::Float32= begin
#  connectedInputCoords= @>> colinputs findall getindex(s.ci)
#  maxc= [mapreduce(c->c.I[d], max, connectedInputCoords) for d in 1:Nin]
#  minc= [mapreduce(c->c.I[d], min, connectedInputCoords) for d in 1:Nin]
#  mean(maxc .- minc .+ 1)
#end


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
step!(s::ProximalSynapses, z,a, params)= adapt!(s.Dₚ, s,z,a,params)

# These are performance optimizations of the simple update methods described in the ProximalSynapses doc
# - minimize allocations and accesses
function adapt!(::DenseSynapses,s::ProximalSynapses, z,a, params)
  @unpack p⁺,p⁻,θ_permanence = params
  Dₚactive= @view s.Dₚ[:,a]
  activeConn=   (Dₚactive .> 0) .&   z
  inactiveConn= (Dₚactive .> 0) .& .!z
  # Learn synapse permanences according to Hebbian learning rule
  @inbounds Dₚactive.= activeConn   .* (Dₚactive .⊕ p⁺) .+
                       inactiveConn .* (Dₚactive .⊖ p⁻)
  # Update cache of connected synapses
  @inbounds s.connected[:,vec(a)].= Dₚactive .> θ_permanence
end
function adapt!(::SparseSynapses,s::ProximalSynapses, z,a, params)
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach((scol,input_i)->
                    learn_sparsesynapses!(scol,input_i, z,params.p⁺,params.p⁻),
                 s.Dₚ, a)
  # Update cache of connected synapses
  @inbounds s.connected[:,a].= s.Dₚ[:,a] .> params.θ_permanence
end
function learn_sparsesynapses!(synapses_activeCol,input_i,z,p⁺,p⁻)
  @inbounds z_i= z[input_i]
  @inbounds synapses_activeCol.= z_i .* (synapses_activeCol .⊕ p⁺) .+
                               .!z_i .* (synapses_activeCol .⊖ p⁻)
end



# ## Distal synapses for the TM
# (assume the same learning rule governs all types of distal synapses)

"""
`DistalSynapses` are lateral connections within a neuron layer that attach to the dendrites of neurons,
not directly to the soma (neuron's center), and can therefore **depolarize** neurons but *can't activate them.*
Compare with [`ProximalSynapses`](@ref).

Used in the context of the [`TemporalMemory`](@ref).

# Description

Neurons have multiple signal integration zones: the soma, proximal dendrites, apical dendrites.
Signals are routed to the proximal dendrites through distal synapses.
This type defines both the synapses themselves and the neuron's dendrites.
"""
mutable struct DistalSynapses
  synapses::SparseSynapses               # Ncell x Nseg
  connected::SparseMatrixCSC{Bool,Int}
  cellSeg::SparseMatrixCSC{Bool,Int}     # Ncell x Nseg
  segCol::SparseMatrixCSC{Bool,Int}      # Nseg x Ncol
  cellϵcol::Int
end
cellXseg(s::DistalSynapses)= s.cellSeg
col2seg(s::DistalSynapses,col::Int)= s.segCol[:,col].nzind
col2seg(s::DistalSynapses,col)= rowvals(s.segCol[:,col])
col2cell(col,cellϵcol)= (col-1)*cellϵcol+1 : col*cellϵcol
cell2col(cells,cellϵcol)= @. (cells-1) ÷ cellϵcol + 1
connected(s::DistalSynapses)= s.connected

# Adapt distal synapses based on TM state at t-1 and current cell/column activity
# A: [Ncell] cell activity
# B: [Ncol] column activity
# WC: [Ncell] current winner cells from predicted columns; add from bursting columns
function step!(s::DistalSynapses,WC,previous::NamedTuple,A,B, params)
  WS= get_grow__winseg_wincell!(s,WC, previous.Πₛ,A, B,previous.ovp_Mₛ,params.θ_stimulus_learn)
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach((scol,cell_i)->
                    learn_sparsesynapses!(scol,cell_i, previous.A,params.p⁺,params.p⁻),
                 s.synapses, WS)
  # Decay unused synapses
  decayS= padfalse(previous.Mₛ,length(WS)) .& (s.cellSeg'*(.!A))
  sparse_foreach((scol,cell_i)->
                    learn_sparsesynapses!(scol,cell_i, .!previous.A,zero(𝕊𝕢),params.LTD_p⁻),
                 s.synapses, decayS)
  growsynapses!(s, previous.WC,WS, previous.ovp_Mₛ,params.synapseSampleSize,params.init_permanence)
  # Update cache of connected synapses
  #@inbounds s.connected[:,WS].= s.synapses[:,WS] .> params.θ_permanence
  s.connected= s.synapses .> params.θ_permanence_dist
end
# Calculate and return WinningSegments, growing new segments where needed.
#   Update WinnerCells with bursting columns.
function get_grow__winseg_wincell!(s,WC, Πₛ,A, B,ovp_Mₛ,θ_stimulus_learn)
  WS_activecol= winningSegments_activecol(s,Πₛ,A)
  WS_burstcol= maxsegϵburstcol!(s,B,ovp_Mₛ,θ_stimulus_learn)
  Nseg= size(s.cellSeg,2)
  WS= (@> WS_activecol padfalse(Nseg)) .| WS_burstcol
  # Update winner cells with entries from bursting columns
  WC[cellXseg(s)*WS_burstcol.>0].= true
  return WS
end
growsynapses!(s, WC::CellActivity,WS, ovp_Mₛ,synapseSampleSize,init_permanence)= begin
  WC= findall(WC)
  !isempty(WC) && _growsynapses!(s, WC,WS, ovp_Mₛ,synapseSampleSize,init_permanence)
end
function _growsynapses!(s, WC,WS, ovp_Mₛ,synapseSampleSize,init_permanence)
  Nnewsyn(ovp)= max(0,synapseSampleSize - ovp)
  Nseg= size(s.cellSeg,2)
  psampling_newsyn= min.(1.0, Nnewsyn.((@> ovp_Mₛ padfalse(Nseg))[WS]) ./ length(WC))
  selectedWC= similar(WC)

  foreach(Truesof(WS), psampling_newsyn) do seg_i, p
    # Bernoulli sampling from WC with mean sample size == Nnewsyn
    randsubseq!(selectedWC,WC,p)
    # Grow new synapses (percolumn manual | setindex percolumn | setindex WC,WS,sparse_V)
    s.synapses[selectedWC, seg_i].= init_permanence
  end
end

# If a cell was previously depolarized and now becomes active, the segments that caused
# the depolarization are winning.
winningSegments_activecol(synapses,Πₛ,A)= Πₛ .& (cellXseg(synapses)'A .>0)
# If a cell is part of a bursting column, the segment in the column with the highest
# overlap wins.
# Foreach bursting col, find the best matching segment or grow one if needed
maxsegϵburstcol!(synapses,B,ovp_Mₛ,θ_stimulus_learn)= begin
  burstingCols= findall(B)
  maxsegs= Vector{Option{Int}}(undef,length(burstingCols))
  map!(col->bestmatch(synapses,col,ovp_Mₛ,θ_stimulus_learn), maxsegs, burstingCols)
  growseg!(synapses,maxsegs,burstingCols)
  Nseg= size(cellXseg(synapses),2)
  @> maxsegs bitarray(Nseg)
end

# Best matching segment for column - or `nothing`
function bestmatch(synapses,col,ovp_Mₛ,θ_stimulus_learn)
  segs= col2seg(synapses,col)
  isempty(segs) && return nothing   # If there's no existing segments in the column
  m,i= findmax(ovp_Mₛ[segs])
  m > θ_stimulus_learn ? segs[i] : nothing
end
# Cell with least segments
function leastusedcell(synapses,col)
  cellsWithSegs= cellXseg(synapses)[:,col2seg(synapses,col)].rowval|> countmap_empty
  cellsWithoutSegs= setdiff(col2cell(col,synapses.cellϵcol), cellsWithSegs|> keys)
  isempty(cellsWithoutSegs) ?
      findmin(cellsWithSegs)[2] : rand(cellsWithoutSegs)
end

# OPTIMIZE add many segments together for efficiency?
function growseg!(synapses::DistalSynapses,maxsegs::Vector{Option{Int}},burstingcolidx)
  cellsToGrow= map(col-> leastusedcell(synapses,col), burstingcolidx[isnothing.(maxsegs)])
  columnsToGrow= cell2col(cellsToGrow,synapses.cellϵcol)
  Ncell= size(synapses.synapses,1); Ncol= size(synapses.segCol,2)
  Nseg_before= size(cellXseg(synapses),2)
  Nseggrow= length(cellsToGrow)  # grow 1 seg per cell
  _grow_synapse_matrices!(synapses,columnsToGrow,cellsToGrow,Nseggrow)
  # Replace in maxsegs, `nothing` with something :-)
  maxsegs[isnothing.(maxsegs)].= Nseg_before.+(1:Nseggrow)
end
function _grow_synapse_matrices!(synapses::DistalSynapses,columnsToGrow,cellsToGrow,Nseggrow)
  synapses.segCol= vcat!!(synapses.segCol, columnsToGrow, trues(Nseggrow))
  synapses.cellSeg= hcat!!(synapses.cellSeg, cellsToGrow,trues(Nseggrow))
  synapses.connected= hcat!!(synapses.connected, cellsToGrow,falses(Nseggrow))
  synapses.synapses= hcat!!(synapses.synapses, Nseggrow)
end

# [Dict] Count the frequency of occurence for each element in x
countmap_empty(x)= isempty(x) ? x : countmap(x)
