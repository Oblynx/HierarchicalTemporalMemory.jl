using SparseArrays
using Lazy
using ImageFiltering
import StatsBase: percentile

# Type aliases
const IntSP= Int32
const UIntSP= UInt32
const FloatSP= Float32
const SynapsePermanenceQuantization= UInt8
const CellActivity= BitArray
const Option{T}= Union{T,Nothing}
const Maybe{T}= Union{T,Missing}
const VecInt{T<:Integer}= Union{Vector{T}, T}

export IntSP, UIntSP, FloatSP, SynapsePermanenceQuantization

include("tupleUtils.jl")
include("iterUtils.jl")
include("synapses.jl")

# Synapses don't belong to regions!
struct Region
end
