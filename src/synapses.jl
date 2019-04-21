# ## Synapse type definitions
# This is low-level code that implements custom Array behavior on synapse permanence arrays

struct DummyArray{N} <: DenseArray{Int,N}
  dims::NTuple{N,Int}
end
Base.size(d::DummyArray)= d.dims

"""
  Synapses is basically a wrapper around a (possibly sparse) matrix.
    Connects pre- & post-synaptic entities.
  Access patterns:
  - pre+post: single synapse
  - pre: broadcast to all post-
  - post: get all pre
"""
abstract type AbstractSynapses{Npre,Npost} <: AbstractMatrix{SynapsePermanenceQuantization}
end
struct SparseSynapses{Npre,Npost} <: AbstractSynapses{Npre,Npost}
  data::SparseMatrixCSC{SynapsePermanenceQuantization,Int}
  preDims::NTuple{Npre,Int}
  postDims::NTuple{Npost,Int}
  preLinIdx::LinearIndices{Npre}
  postLinIdx::LinearIndices{Npost}
  function SparseSynapses{Npre,Npost}(data,preDims,postDims) where {Npre,Npost}
    preLinIdx= LinearIndices(preDims)
    postLinIdx= LinearIndices(postDims)
    new{Npre,Npost}(data,preDims,postDims,preLinIdx,postLinIdx);
  end
end
struct DenseSynapses{Npre,Npost} <: AbstractSynapses{Npre,Npost}
  data::Array{SynapsePermanenceQuantization, 2}
  preDims::NTuple{Npre,Int}
  postDims::NTuple{Npost,Int}
  preLinIdx::LinearIndices{Npre}
  postLinIdx::LinearIndices{Npost}
  function DenseSynapses{Npre,Npost}(data,preDims,postDims) where {Npre,Npost}
    preLinIdx= LinearIndices(preDims)
    postLinIdx= LinearIndices(postDims)
    new{Npre,Npost}(data,preDims,postDims,preLinIdx,postLinIdx);
  end
end

function (DenseSynapses(preDims::NTuple{Npre,Int}, postDims::NTuple{Npost,Int}, fInit= zeros)
          where {Npre,Npost})
  DenseSynapses{Npre,Npost}(
    fInit(SynapsePermanenceQuantization, prod(preDims), prod(postDims)),
    preDims,
    postDims
  )
end
function (SparseSynapses(preDims::NTuple{Npre,Int}, postDims::NTuple{Npost,Int}, fInit= spzeros)
          where {Npre,Npost})
  SparseSynapses{Npre,Npost}(
    fInit(SynapsePermanenceQuantization, prod(preDims), prod(postDims)),
    preDims,
    postDims
  )
end


# ## Common methods

Base.size(S::AbstractSynapses)= size(S.data)
Base.show(S::AbstractSynapses)= show(S.data)
Base.show(io::IO, mime::MIME"text/plain", S::AbstractSynapses)= show(io,mime,S.data)
Base.display(S::AbstractSynapses)= display(S.data)
Base.similar(S::AbstractSynapses, ::Type{elT}, idx::Dims) where {elT}=
    similar(S.data, elT, idx)
Base.getindex(S::AbstractSynapses, I...)=
    error("AbstractSynapses instances can only be indexed with 2 tuples: pre- & post-synaptic coords")
Base.@propagate_inbounds \
Base.getindex(S::AbstractSynapses, linIdx)= S.data[linIdx]
Base.lastindex(::AbstractSynapses, d)=
    error("'end' can't be used to index AbstractSynapses, because the dimension to which it refers isn't clear")


# ## Dense Synapses
Base.@propagate_inbounds \
Base.getindex(S::DenseSynapses, linIdxPre::Int,linIdxPost::Int)= S.data[linIdxPre,linIdxPost]
Base.@propagate_inbounds \
Base.getindex(S::DenseSynapses, iPre,iPost)=
  getdata(S.data,
    (@>> iPre  syn_toindices(S.preDims)  linIdx(S.preLinIdx) ),
    (@>> iPost syn_toindices(S.postDims) linIdx(S.postLinIdx))
  )
Base.@propagate_inbounds \
Base.view(S::DenseSynapses, iPre,iPost)=
  viewdata(S.data,
    (@>> iPre  syn_toindices(S.preDims)  linIdx(S.preLinIdx) ),
    (@>> iPost syn_toindices(S.postDims) linIdx(S.postLinIdx))
  )
Base.@propagate_inbounds \
Base.setindex!(S::DenseSynapses, v,iPre,iPost)=
  setdata!(S.data,v,
    (@>> iPre  syn_toindices(S.preDims)  linIdx(S.preLinIdx) ),
    (@>> iPost syn_toindices(S.postDims) linIdx(S.postLinIdx))
  )


# ## Sparse Synapses

SparseArrays.nnz(S::SparseSynapses)= nnz(S.data)

# Special getindex for indexing with 2 tuples {pre,post}
Base.@propagate_inbounds \
function Base.getindex(S::SparseSynapses{Npre,Npost}, Ipre::VecTuple{Npre,T},
    Ipost::VecTuple{Npost,T}) where {Npre,Npost,T<:Integer}
  expand_i()::NTuple{Npre+Npost,VecInt{Int}}= Tuple([collect(expand(Ipre));collect(expand(Ipost))])
  I_expanded= expand_i()
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
  expand_i()::NTuple{Npre+Npost,VecInt{Int}}= Tuple([collect(expand(Ipre));collect(expand(Ipost))])
  I_expanded= expand_i()
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
Base.getindex(iter::LinearIndices{N}, i::NTuple{N,Vector{Int}}) where N=
    map(i->iter[i...], collect(zip(i...)))
Base.getindex(iter::LinearIndices{N}, i::Vector{NTuple{N,Int}}) where N=
    map(i-> iter[i...], i)
linIdx(linIdxArray, idx::NTuple{N,Int}) where N= linIdxArray[idx...]::Int
linIdx(linIdxArray, idx::CartesianIndex)= linIdxArray[idx]::Int
linIdx(linIdxArray, idx::Vector{NTuple{N,Int}}) where N=
    vec(linIdxArray[idx])::Vector{Int}
linIdx(linIdxArray, idx::Tuple)= vec(linIdxArray[idx...])::Vector{Int}
linIdx(linIdxArray, idx)= (linIdx(linIdxArray, i) for i in idx)


syn_toindices(d, i::NTuple{N,Int}) where N= i
syn_toindices(d, i::CartesianIndex)= i
syn_toindices(d, i::Vector{NTuple{N,Int}}) where N= i
syn_toindices(d, i::Tuple)= @>> i to_indices(DummyArray(d))
# Generic iterable
#syn_toindices(d, i)= @>> i vecTuple_2_tupleVec to_indices(DummyArray(d))
syn_toindices(d,i)= (syn_toindices(d,idx) for idx in i)

# Preallocates the output array to preserve the shape, even though it would have been much
#   simpler otherwise!
getdata(data,iPre,iPost)= begin
  _getdata!(::Val{true},::Val{true},d, data,iPre,iPost)=
      foreach(()-> d.= data[iPre,iPost])
  _getdata!(::Val{true},::Val{false},d, data,iPre,iPost)=  foreach(post-> length(iPre)>1 ?
        d[:,post[1]]= data[iPre,post[2]] : d[post[1]]= data[iPre,post[2]],
      enumerate(iPost))
  _getdata!(::Val{false},::Val{true},d, data,iPre,iPost)=  foreach(pre-> length(iPost)>1 ?
        d[pre[1],:]= data[pre[2],iPost] : d[pre[1]]= data[pre[2],iPost],
      enumerate(iPre))
  _getdata!(::Val{false},::Val{false},d, data,iPre,iPost)= foreach(i-> begin
        (pre,post)= i
        d[pre[1],post[1]]= data[pre[2],post[2]]
      end, Iterators.product(enumerate(iPre),enumerate(iPost)))

  # Preallocate the output array
  d= all(length.((iPost,iPre)).>1) ?
      Array{SynapsePermanenceQuantization}(undef,length.((iPre,iPost))) :
      length(iPost)>1 || length(iPre)>1 ?
        Array{SynapsePermanenceQuantization}(undef,length.((iPre,iPost))|> maximum) :
        Array{SynapsePermanenceQuantization}(undef,1)
  _getdata!(iseager(iPre),iseager(iPost),d, data,iPre,iPost)
  # If the output should be scalar, unwrap from array
  all(length.((iPost,iPre)).==1) ? d= d[1] : nothing
  return d
end
viewdata(data,iPre,iPost)= view(data,collect(iPre),collect(iPost))
setdata!(data,v,iPre,iPost)= begin
  _setdata!(::Val{true},::Val{true},data,v,iPre,iPost)=
      foreach(()-> data[iPre,iPost]=v)
  _setdata!(::Val{true},::Val{false},data,v,iPre,iPost)=  foreach(post->
      data[iPre,post[2]]= length(iPre)>1 ? v[:,post[1]] : v[post[1]], enumerate(iPost))
  _setdata!(::Val{false},::Val{true},data,v,iPre,iPost)=  foreach(pre->
      data[pre[2],iPost]= length(iPost)>1 ? v[pre[1],:] : v[pre[1]], enumerate(iPre))
  _setdata!(::Val{false},::Val{false},data,v,iPre,iPost)= foreach(i-> begin
      (pre,post)= i
      data[pre[2],post[2]]= v[pre[1],post[1]]
    end,  Iterators.product(enumerate(iPre),enumerate(iPost)))
  _setdata!(iseager(iPre),iseager(iPost),data,v,iPre,iPost)
end

# Iterators are Lazy, everything else is eager
iseager(::Int)= Val(true)
iseager(::Vector)= Val(true)
iseager(::Any)= Val(false)
