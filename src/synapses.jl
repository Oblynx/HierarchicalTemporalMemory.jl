# ## Synapse type definitions
"""
  Synapses is basically a wrapper around a (possibly sparse) matrix.
    Connects pre- & post-synaptic entities.
  Access patterns:
  - pre+post: single synapse
  - pre: broadcast to all post-
  - post: get all pre
"""
abstract type AbstractSynapses{Npre,Npost,Nsum} <: AbstractArray{SynapsePermanenceQuantization,Nsum}
end
struct SparseSynapses{Npre,Npost,Nsum} <: AbstractSynapses{Npre,Npost,Nsum}
  data::SparseMatrixCSC{SynapsePermanenceQuantization,Int}
  preDims::NTuple{Npre,Int}
  postDims::NTuple{Npost,Int}
  preLinIdx::LinearIndices{Npre}
  postLinIdx::LinearIndices{Npost}
  function SparseSynapses{Npre,Npost,Nsum}(data,preDims,postDims) where {Npre,Npost,Nsum}
    Npre+Npost == Nsum || error("Nsum must be Npre+Npost")
    preLinIdx= LinearIndices(preDims)
    postLinIdx= LinearIndices(postDims)
    new{Npre,Npost,Nsum}(data,preDims,postDims,preLinIdx,postLinIdx);
  end
end
struct DenseSynapses{Npre,Npost,Nsum} <: AbstractSynapses{Npre,Npost,Nsum}
  data::Array{SynapsePermanenceQuantization, Nsum}
  preDims::NTuple{Npre,Int}
  postDims::NTuple{Npost,Int}
  function DenseSynapses{Npre,Npost,Nsum}(data,preDims,postDims) where {Npre,Npost,Nsum}
    Npre+Npost == Nsum || error("Nsum must be Npre+Npost")
    new{Npre,Npost,Nsum}(data,preDims,postDims);
  end
end

function (DenseSynapses(preDims::NTuple{Npre,IntT}, postDims::NTuple{Npost,IntT}, fInit= zeros)
          where {Npre,Npost, IntT<:Integer})
  DenseSynapses{Npre,Npost,Npre+Npost}(
    fInit(SynapsePermanenceQuantization, preDims..., postDims...),
    preDims,
    postDims
  )
end
function (SparseSynapses(preDims::NTuple{Npre,IntT}, postDims::NTuple{Npost,IntT}, fInit= spzeros)
          where {Npre,Npost, IntT<:Integer})
  SparseSynapses{Npre,Npost,Npre+Npost}(
    fInit(SynapsePermanenceQuantization, prod(preDims), prod(postDims)),
    preDims,
    postDims
  )
end


# ## Common methods

Base.size(S::AbstractSynapses)= (S.preDims..., S.postDims...) #size(S.data)
Base.show(S::AbstractSynapses)= show(S.data)
Base.show(io, mime::MIME"text/plain", S::AbstractSynapses)= show(io,mime,S.data)
Base.display(S::AbstractSynapses)= display(S.data)
Base.similar(S::AbstractSynapses, ::Type{elT}, idx::Dims) where {elT}=
    similar(S.data, elT, idx)


# ## Dense Synapses

# Special getindex! for indexing with 2 tuples {pre,post}
Base.@propagate_inbounds \
function Base.getindex(S::DenseSynapses{Npre,Npost}, Ipre::VecTuple{Npre,T},
    Ipost::VecTuple{Npost,T}) where {Npre,Npost,T<:Integer}
  I_expanded= Tuple([collect(expand(Ipre));collect(expand(Ipost))])
  # vec: to return Vector even if i is a single Tuple
  iArray(i)= vec(collect(zip(i...)))
  S.data[cartesianIdx(iArray(I_expanded[1:Npre]), iArray(I_expanded[Npre+1:Npre+Npost]))]
end
Base.@propagate_inbounds \
Base.getindex(S::DenseSynapses, I::Vararg{Int,N}) where {N}= S.data[I...]

# Special setindex! for indexing with 2 tuples {pre,post}
Base.@propagate_inbounds \
function Base.setindex!(S::DenseSynapses{Npre,Npost}, v, Ipre::VecTuple{Npre,T},
    Ipost::VecTuple{Npost,T}) where {Npre,Npost,T<:Integer}
  I_expanded= Tuple([collect(expand(Ipre));collect(expand(Ipost))])
  # vec: to return Vector even if i is a single Tuple
  iArray(i)= vec(collect(zip(i...)))
  S.data[cartesianIdx(iArray(I_expanded[1:Npre]), iArray(I_expanded[Npre+1:Npre+Npost]))]= v
end
Base.@propagate_inbounds \
Base.setindex!(S::DenseSynapses, v, I::Vararg{Int,N}) where {N}= (S.data[I...]= v)


# ## Sparse Synapses

SparseArrays.nnz(S::SparseSynapses)= nnz(S.data)

# Special getindex for indexing with 2 tuples {pre,post}
Base.@propagate_inbounds \
function Base.getindex(S::SparseSynapses{Npre,Npost}, Ipre::VecTuple{Npre,T},
    Ipost::VecTuple{Npost,T}) where {Npre,Npost,T<:Integer}
  I_expanded= Tuple([collect(expand(Ipre));collect(expand(Ipost))])
  idx= to_indices(S,I_expanded)
  S.data[linIdx(S.preLinIdx,idx[1:Npre]), linIdx(S.postLinIdx,idx[Npre+1:Npre+Npost])]
end
Base.@propagate_inbounds \
function Base.getindex(S::SparseSynapses{Npre,Npost}, I...) where {Npre,Npost}
  idx= to_indices(S,I)
  S.data[linIdx(S.preLinIdx,idx[1:Npre]), linIdx(S.postLinIdx,idx[Npre+1:Npre+Npost])]
end

# Special setindex! for indexing with 2 tuples {pre,post}
Base.@propagate_inbounds \
function Base.setindex!(S::SparseSynapses{Npre,Npost}, v, Ipre::VecTuple{Npre,T},
    Ipost::VecTuple{Npost,T}) where {Npre,Npost,T<:Integer}
  I_expanded= Tuple([collect(expand(Ipre));collect(expand(Ipost))])
  idx= to_indices(S,I_expanded)
  _setindex_array!(S,v,idx)
end
Base.@propagate_inbounds \
function Base.setindex!(S::SparseSynapses{Npre,Npost}, v, I...) where {Npre,Npost}
  #length(I) == Npre+Npost || error("All dimensions must be specified when accessing SparseSynapses")
  idx= to_indices(S,I)
  _setindex_array!(S,v,idx)
end

Base.@propagate_inbounds \
_setindex_array!(S::SparseSynapses{Npre,Npost}, v::Integer, idx::NTuple{N,<:Integer}) where {Npre,Npost,N}=
    S.data[linIdx(S.preLinIdx,idx[1:Npre]), linIdx(S.postLinIdx,idx[Npre+1:Npre+Npost])]= v
Base.@propagate_inbounds \
function _setindex_array!(S::SparseSynapses{Npre,Npost}, v, idx) where {Npre,Npost}
  idxPre= linIdx(S.preLinIdx, idx[1:Npre])
  idxPost= linIdx(S.postLinIdx, idx[Npre+1:Npre+Npost])
  S.data[idxPre, idxPost]= reshape(v, length(idxPre), length(idxPost))
end

# TODO optimize views into SparseSynapses
#   Views into sparse matrices lack specialized methods for mostly everything. But it looks
#   like they can be implemented easily wrt. view.parent
#   See https://github.com/JuliaLang/julia/issues/21796#issuecomment-457203294


# ## Utility

# When indexing into a LinearIndices with Vectors {i,j}, output Kronecker product {i⊗j}
Base.@propagate_inbounds \
Base.getindex(iter::LinearIndices{N}, i::Vararg{Vector{<:Integer},N}) where N=
    map(i->iter[i...], collect(zip(i...)))
linIdx(linIdxArray, idx::NTuple{N,<:Integer}) where N= linIdxArray[idx...]
linIdx(linIdxArray, idx)= vec(linIdxArray[idx...])
