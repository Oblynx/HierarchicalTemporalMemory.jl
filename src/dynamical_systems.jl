# ## Inhibition Radius

"""
The inhibition radius of a Spatial Pooler's columns is a dynamical system that evolves
under the influence of other elements of the Spatial Pooler. It provides an init
(constructor) and a step! function.
"""
mutable struct InhibitionRadius{Nin} <:AbstractFloat
  φ::Float32
  sp_input_ratio::Float32
  ci::CartesianIndices{Nin}
  InhibitionRadius(x,inputSize::NTuple{Nin,Int},sp_input_ratio,enable_local_inhibit=true) where Nin=
      enable_local_inhibit ?
        (x>=0 ? new{Nin}(x * mean(sp_input_ratio), mean(sp_input_ratio),
                          CartesianIndices(map(d->1:d, inputSize))) :
          error("Inhibition radius >0")) :
        new{0}(maximum(sp_input_ratio.*inputSize)+1)
end
Base.convert(::Type{InhibitionRadius}, x::InhibitionRadius)= x
Base.convert(::Type{N}, x::InhibitionRadius) where {N<:Number}= convert(N,x.φ)
Base.promote_rule(::Type{InhibitionRadius}, ::Type{T}) where {T<:Number}= Float32
Float32(x::InhibitionRadius)= x.φ
Int(x::InhibitionRadius)= round(Int,x.φ)

step!(s::InhibitionRadius{0}, a,W,params)= nothing
function step!(s::InhibitionRadius{Nin}, a, W, params) where Nin
  # This implementation follows the SP paper description and NUPIC, but seems too complex
  #   for no reason. Replace with a static inhibition radius instead
  #receptiveFieldSpan(colinputs)::Float32= begin
  #  connectedInputCoords= @>> colinputs findall getindex(s.ci)
  #  maxc= [mapreduce(c->c.I[d], max, connectedInputCoords) for d in 1:Nin]
  #  minc= [mapreduce(c->c.I[d], min, connectedInputCoords) for d in 1:Nin]
  #  mean(maxc .- minc .+ 1)
  #end
  #mean_receptiveFieldSpan()::Float32= mapslices(receptiveFieldSpan, W, dims=1)|> mean
  mean_receptiveFieldSpan()= (params.input_potentialRadius*2+0.5)*(1-params.θ_potential_prob_prox)
  diameter= mean_receptiveFieldSpan()*s.sp_input_ratio
  s.φ= @> (diameter-1)/2 max(1)
end


# ## Proximal Synapses

const permT= SynapsePermanenceQuantization
struct ProximalSynapses{SynapseT<:AbstractSynapses,ConnectedT}
  synapses::SynapseT
  connected::ConnectedT

  """
  Make an input x spcols synapse permanence matrix
  params: includes size (num of cols)
  Initialize potential synapses. For every column:
  - find its center in the input space
  - for every input in hypercube, draw rand Z
    - If < 1-θ_potential_prob_prox
     - Init perm: rescale Z from [0..1-θ] -> [0..1]: Z/(1-θ)
  """
  function ProximalSynapses(inputSize,spSize,synapseSparsity,input_potentialRadius,
        θ_potential_prob_prox,θ_permanence_prox)
    spColumns()= CartesianIndices(spSize)
    # Map column coordinates to their center in the input space. Column coords FROM 1 !!!
    xᶜ(yᵢ)= floor.(UIntSP, (yᵢ.-1) .* (inputSize./spSize)) .+1
    xᵢ(xᶜ)= hypercube(xᶜ,input_potentialRadius, inputSize)

    # Draw permanences from uniform distribution. Connections aren't very sparse (40%),
    #   so prefer a dense matrix
    permanences(::Type{SparseSynapses},xᵢ)= sprand(permT,length(xᵢ),1, 1-θ_potential_prob_prox)
    permanences(::Type{DenseSynapses}, xᵢ)= begin
      p= rand(permT(0):typemax(permT),length(xᵢ),1)
      effective_θ= floor(permT, (1-θ_potential_prob_prox)*typemax(permT))
      p0= p .> effective_θ; pScale= p .< effective_θ
      fill!(view(p,p0), permT(0))
      rand!(view(p,pScale), permT(0):typemax(permT))
      return p
    end
    fillin!(proximalSynapses)= begin
      for yᵢ in spColumns()
        yᵢ= yᵢ.I
        xi= xᵢ(xᶜ(yᵢ))
        proximalSynapses[xi, yᵢ]= permanences(SynapseT,xi)
      end
      return proximalSynapses
    end

    SynapseT= synapseSparsity<0.08 ? SparseSynapses : DenseSynapses
    ConnectedT= synapseSparsity<0.08 ? SparseMatrixCSC{Bool} : Matrix{Bool}
    proximalSynapses= SynapseT(inputSize,spSize)
    fillin!(proximalSynapses)
    new{SynapseT,ConnectedT}(proximalSynapses, proximalSynapses .> θ_permanence_prox)
  end
end
connected(s::ProximalSynapses)= s.connected

function adapt!(::DenseSynapses,s::ProximalSynapses, z,a, params)
  synapses_activeSP= @view s.synapses[:,a]
  activeConn=   @. (synapses_activeSP>0) &  z
  inactiveConn= @. (synapses_activeSP>0) & !z

  # Learn synapse permanences according to Hebbian learning rule
  @inbounds @. (synapses_activeSP= activeConn * (synapses_activeSP ⊕ params.p⁺) +
      inactiveConn * (synapses_activeSP ⊖ params.p⁻))
  # Update cache of connected synapses
  @inbounds s.connected[:,vec(a)].= synapses_activeSP .> params.θ_permanence_prox
end
function adapt!(::SparseSynapses,s::ProximalSynapses, z,a, params)
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach(s.synapses,a) do s,col_i,input_i
    @inbounds synapses_activeCol= @view nonzeros(s)[col_i]
    @inbounds z_i= z[input_i]
    @inbounds synapses_activeCol.= z_i .* (synapses_activeCol .⊕ params.p⁺) .+
                                 .!z_i .* (synapses_activeCol .⊖ params.p⁻)
  end
  # Update cache of connected synapses
  @inbounds s.connected[:,a].= s.synapses.data[:,a] .> params.θ_permanence_prox
end
step!(s::ProximalSynapses, z,a, params)= adapt!(s.synapses, s,z,a,params)


# ## Boosting factors

struct Boosting <:DenseArray{Float32,1}
  b::Vector{Float32}
  a_Tmean::Array{Float32}
  a_Nmean::Array{Float32}
  Boosting(b,spSize)= (b.>0)|> all ? new(b, zeros(spSize), zeros(spSize)) :
                              error("Boosting factors >0")
end
Base.size(b::Boosting)= size(b.b)
Base.getindex(b::Boosting, i::Int)= b.b[i]

function step!(s::Boosting, a_t::CellActivity, φ,T,β, local_inhibit,enable)
  mean_kernel(Ndim)= ones(ntuple(i->α(φ),Ndim)) ./ α(φ).^Ndim
  a_Nmean!(aN,aT, local_inhibit::Val{true})=
      imfilter!(aN,aT, aN|>size|>length|>mean_kernel, "symmetric")
  a_Nmean!(aN,aT, local_inhibit::Val{false})= (aN.= mean(aT))

  s.a_Tmean.= s.a_Tmean*(T-1)/T .+ a_t/T
  a_Nmean!(s.a_Nmean, s.a_Tmean, Val(local_inhibit))
  if enable
    s.b.= boostfun.(s.a_Tmean, s.a_Nmean, β)|> vec
  end
end
boostfun(a_Tmean,a_Nmean,β)= ℯ^(-β*(a_Tmean-a_Nmean))


# ## Distal synapses for the TM
# (assume the same learning rule governs all types of distal synapses)

mutable struct DistalSynapses
  synapses::SparseSynapses              # Ncell x Nseg
  connected::SparseMatrixCSC{Bool,Int}
  cellSeg::SparseMatrixCSC{Bool,Int}    # Ncell x Nseg
  segCol::SparseMatrixCSC{Bool,Int}     # Nseg x Ncol
  cellϵcol::Int
  rng::Xoroshiro128Plus
end
cellXseg(s::DistalSynapses)= s.cellSeg
col2seg(s::DistalSynapses,col::Int)= s.segCol[:,col].nzind
col2seg(s::DistalSynapses,col)= s.segCol[:,col].rowval
col2cell(col,cellϵcol)= (col-1)*cellϵcol+1 : col*cellϵcol
cell2col(cells,cellϵcol)= @. (cells-1) ÷ cellϵcol + 1
connected(s::DistalSynapses,θ)= s.synapses.data .> θ

# Adapt distal synapses based on TM state at t-1 and current cell/column activity
# A: [Ncell] cell activity
# B: [Ncol] column activity
function step!(s::DistalSynapses,previous::NamedTuple,A,B, params)
  WS= winningSegments(s,previous,A,B)
  # Learn synapse permanences according to Hebbian learning rule
  sparse_foreach(s.synapses, WS) do s,seg_i,cell_i
    @inbounds synapses_winSeg= @view nonzeros(s)[seg_i]
    @inbounds A_i= A[cell_i]
    @inbounds synapses_winSeg.= A_i .* (synapses_winSeg .⊕ params.p⁺) .+
                              .!A_i .* (synapses_winSeg .⊖ params.p⁻)

    # TODO: grow new synapses to A
  end

  @debug WS
  # Update cache of connected synapses
  #@inbounds s.connected[:,WS].= s.synapses.data[:,WS] .> params.θ_permanence_prox
end
# If a cell was previously depolarized and now becomes active, the segments that caused
# the depolarization are winning.
# If a cell is part of a bursting column, the segment in the column with the highest
# overlap wins.
winningSegments(synapses,previous,A,B)=
    (previous.Πₛ .& (cellXseg(synapses)'A)) .| maxsegϵcol(synapses,A,B,previous.segOvp)
# Foreach bursting col, find the best matching segment or grow one if needed
maxsegϵcol(synapses,A,B,segOvp)= begin
  maxsegs= map(col-> bestmatch(synapses,col,segOvp), Truesof(B))
  @debug maxsegs
  growseg!(synapses,maxsegs,findall(B))
  @debug maxsegs
  bitarray(length(segOvp), maxsegs)
end

# Best matching segment for column - or `nothing`
function bestmatch(synapses,col,segOvp)
  segs= col2seg(synapses,col)
  isempty(segs) && return nothing   # If there's no existing segments in the column
  m,i= findmax(segOvp[segs])
  m > 0 ? segs[i] : nothing
end
# Cell with least segments
function leastusedcell(synapses,col)
  cellsWithSegs= cellXseg(synapses)[:,col2seg(synapses,col)].rowval|> countmap
  cellsWithoutSegs= setdiff(col2cell(col,synapses.cellϵcol), cellsWithSegs)
  isempty(cellsWithoutSegs) ?
      findmin(cellsWithSegs)[2] : rand(synapses.rng, cellsWithoutSegs)
end

# NOTE Should be idempotent! Maybe check with / update segOvp?
# OPTIMIZE add many segments together for efficiency?
function growseg!(synapses,maxsegs,colidx)
  cellsToGrow= leastusedcell.(Ref(synapses),colidx)   # Ref() to cancel broadcasting
  columnsToGrow= cell2col(cellsToGrow,synapses.cellϵcol)
  @debug cellsToGrow, columnsToGrow
  Ncell= size(synapses.synapses,1); Ncol= size(synapses.segCol,2)
  Nseggrow= length(cellsToGrow)  # grow 1 seg per cell

  # Grow the synapse arrays
  synapses.segCol= vcat!!(synapses.segCol, columnsToGrow, trues(Nseggrow))
  synapses.cellSeg= hcat!!(synapses.cellSeg, cellsToGrow,trues(Nseggrow))
  synapses.connected= hcat!!(synapses.connected, cellsToGrow,falses(Nseggrow))
                     # TODO SparseSynapses

  #synapses.segCol= vcat(synapses.segCol,
  #                   sparse(1:Nseggrow,columnsToGrow,trues(Nseggrow),Nseggrow,Ncol))
  #synapses.cellSeg= hcat(synapses.cellSeg,
  #                   sparse(cellsToGrow,1:Nseggrow,trues(Nseggrow),Ncell,Nseggrow))
  #synapses.connected= hcat(synapses.connected,
  #                   sparse(cellsToGrow,1:Nseggrow,falses(Nseggrow),Ncell,Nseggrow))
end
