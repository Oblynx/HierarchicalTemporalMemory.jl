using SparseArrays
using Lazy
using ImageFiltering
import Random: rand!
import Statistics: mean

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

include("utils/tuple_utils.jl")
include("utils/iter_utils.jl")
include("utils/arithmetic_utils.jl")
include("utils/synapses.jl")

# Synapses don't belong to regions!
struct Region
end
