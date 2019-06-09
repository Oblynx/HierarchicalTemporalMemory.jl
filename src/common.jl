using SparseArrays
using Parameters
using Lazy: @>, @>>
import ImageFiltering: mapwindow, imfilter!, Fill
import Random: rand!, randsubseq!
import LinearAlgebra: Adjoint
import Statistics: mean
import StatsBase: countmap, quantile

# Type aliases
const Option{T}= Union{T,Nothing}
const Maybe{T}= Union{T,Missing}
const VecInt{T<:Integer}= Union{Vector{T}, T}
const 𝕊𝕢= UInt8
const 𝕊𝕢range= 𝕊𝕢(0):typemax(𝕊𝕢)

const CellActivity= BitArray
const DenseSynapses= Matrix{𝕊𝕢}
const SparseSynapses= SparseMatrixCSC{𝕊𝕢}
const AnySynapses= Union{DenseSynapses,SparseSynapses}
const DenseConnection= Matrix{Bool}
const SparseConnection= SparseMatrixCSC{Bool}
const AnyConnection= Union{DenseConnection,SparseConnection}

include("utils/tuple_utils.jl")
include("utils/iter_utils.jl")
include("utils/array_utils.jl")
include("utils/arithmetic_utils.jl")
