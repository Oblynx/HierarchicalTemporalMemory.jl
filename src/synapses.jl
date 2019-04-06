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
Base.show(S::SparseSynapses)= show(S.data)
Base.show(io, mime::MIME"text/plain", S::SparseSynapses)= show(io,mime,S.data)
Base.similar(S::AbstractSynapses, ::Type{elT}, idx::Vararg{Int,N}) where {elT,N}=
    similar(S.data, elT, idx)

Base.@propagate_inbounds \
Base.getindex(S::DenseSynapses, I::Vararg{Int,N}) where {N}= S.data[I...]
    #get(S.data, I, zero(SynapsePermanenceQuantization))
Base.setindex!(S::DenseSynapses, v, I::Vararg{Int,N}) where {N}= (S.data[I...]= v)

Base.@propagate_inbounds \
function Base.getindex(S::SparseSynapses{Npre,Npost}, I...) where {Npre,Npost}
  idx= to_indices(S,I)
  S.data[S.preLinIdx[idx[1:Npre]...], S.postLinIdx[idx[Npre+1:Npre+Npost]...]]
end

Base.@propagate_inbounds \
function Base.setindex!(S::SparseSynapses{Npre,Npost}, v, I...) where {Npre,Npost,N}
  #length(I) == Npre+Npost || error("All dimensions must be specified when accessing SparseSynapses")
  idx= to_indices(S,I)
  S.data[S.preLinIdx[idx[1:Npre]...], S.postLinIdx[idx[Npre+1:Npre+Npost]...]]= v
end

SparseArrays.nnz(S::SparseSynapses)= nnz(S.data)

# TODO optimize views into SparseSynapses
#   Views into sparse matrices lack specialized methods for mostly everything. But it looks
#   like they can be implemented easily wrt. view.parent
#   See https://github.com/JuliaLang/julia/issues/21796#issuecomment-457203294
