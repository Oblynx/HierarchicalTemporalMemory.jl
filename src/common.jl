module Common

# Type aliases
const IntSP= Int32
const UIntSP= UInt32
const FloatSP= Float32
const SynapsePermanenceQuantization= Int8

export IntSP, UIntSP, FloatSP, SynapsePermanenceQuantization

"""
  Synapses is basically a wrapper around a sparse matrix. Connects pre- & post-synaptic entities.
  Access patterns:
  - pre+post: single synapse
  - pre: broadcast to all post-
  - post: get all pre
"""
struct Synapses{Ndim} #<: AbstractArray{SynapsePermanenceQuantization,Ndim}
  data::SparseMatrixCSC{SynapsePermanenceQuantization,Int}
  dims::Vector{Int}
end
include("Synapses.jl")

const CellActivity= BitArray

# Synapses don't belong to regions!
struct Region
end

end
