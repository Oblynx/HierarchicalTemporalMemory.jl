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
  postLinIdx::LinearIndices{Npre}
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

# TODO: Implement Constructors for specific types
# TODO: Implement getindex for Abstract
# TODO: Implement setindex! for Abstract

function (DenseSynapses(preDims::NTuple{Npre,Int}, postDims::NTuple{Npost,Int}, fInit= zeros)
          where {Npre,Npost})
  DenseSynapses{Npre,Npost,Npre+Npost}(
    fInit(SynapsePermanenceQuantization, preDims..., postDims...),
    preDims,
    postDims
  )
end
function (SparseSynapses(preDims::NTuple{Npre,Int}, postDims::NTuple{Npost,Int}, fInit= spzeros)
          where {Npre,Npost})
  SparseSynapses{Npre,Npost,Npre+Npost}(
    fInit(SynapsePermanenceQuantization, prod(preDims), prod(postDims)),
    preDims,
    postDims
  )
end

Base.size(S::AbstractSynapses)= (S.preDims..., S.postDims...) #size(S.data)
#Base.axes(S::AbstractSynapses)= axes(S.data)
Base.show(S::SparseSynapses)= show(S.data)
Base.show(io, mime::MIME"text/plain", S::SparseSynapses)= show(io,mime,S.data)
Base.similar(S::AbstractSynapses, ::Type{elT}, idx) where {elT}=
    similar(S.data, elT, idx)

Base.@propagate_inbounds \
Base.getindex(S::DenseSynapses, I::Vararg{Int,N}) where {N}= S.data[I...]
    #get(S.data, I, zero(SynapsePermanenceQuantization))
Base.setindex!(S::DenseSynapses, v, I::Vararg{Int,N}) where {N}= (S.data[I...]= v)

# NOTE(optim): try to coalesce S.pre/postLinIdx accesses with a custom
#   to_indices(::SparseSynapses, ...)
#function Base.getindex(S::SparseSynapses{Npre,Npost}, I::Vararg{Int,N}) where {Npre,Npost,N}
#  length(I) == Npre+Npost || error("All dimensions must be specified when accessing SparseSynapses")
#  pre= S.preLinIdx[CartesianIndices(I[1:Npre])]
#  post= S.postLinIdx[CartesianIndices(I[Npre+1:Npre+Npost])]
#  S.data[pre,post]
#end

# This is a copy of the AbstractArray getindex implementation (./abstractarray.jl),
#   hijacked to perform coalesced index indirection for SparseSynapses
Base.@propagate_inbounds \
function Base.getindex(S::SparseSynapses{Npre,Npost}, I...) where {Npre,Npost}
  cartesianIdx(idx::NTuple{N,Int}) where {N}= CartesianIndex(idx)
  cartesianIdx(idx::Tuple)= CartesianIndices(idx)
  linearIdx(cidx::CartesianIndex, linTransform)= linTransform[cidx]
  linearIdx(cidx::CartesianIndices, linTransform)= vec(linTransform[cidx])
  idx= to_indices(S,I)
  S.data[linearIdx(cartesianIdx(idx[1:Npre]),            S.preLinIdx),
         linearIdx(cartesianIdx(idx[Npre+1:Npre+Npost]), S.postLinIdx)]
end
#Base.@propagate_inbounds \
#function Base.getindex(::IndexCartesian, S::SparseSynapses{Npre,Npost}, I::Tuple
#                      ) where {Npre,Npost}
#  preI= I[1:Npre]
#  postI= I[Npre+1:Npre+Npost]
#  @debug preI
#  @debug postI
#  cPreI= CartesianIndices(preI)
#  cPostI= CartesianIndices(postI)
#  @debug cPreI
#  @debug cPostI
#  pre= vec(S.preLinIdx[cPreI])
#  post= vec(S.postLinIdx[cPostI])
#  @debug pre
#  @debug post
#  S.data[pre,post]
#end

function Base.setindex!(S::SparseSynapses{Npre,Npost}, v, I::Vararg{Int,N}) where {Npre,Npost,N}
  length(I) == Npre+Npost || error("All dimensions must be specified when accessing SparseSynapses")
  pre= S.preLinIdx[CartesianIndex(I[1:Npre])]
  post= S.postLinIdx[CartesianIndex(I[Npre+1:Npre+Npost])]
  S.data[pre,post]= v
end

SparseArrays.nnz(S::SparseSynapses)= nnz(S.data)
