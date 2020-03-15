using SparseArrays
using Parameters
using Lazy: @>, @>>
import ImageFiltering: mapwindow, imfilter!, Fill
import Random: rand!, randsubseq!
import LinearAlgebra: Adjoint
import Statistics: mean, median, quantile
import StatsBase: countmap

# Type aliases

const Option{T}= Union{T,Nothing}
const Maybe{T}= Union{T,Missing}
const VecInt{T<:Integer}= Union{Vector{T}, T}
"𝕊𝕢 is the type of connection permanences, defining their quantization domain"
const 𝕊𝕢= UInt8
"𝕊𝕢range is the domain of connection permanence quantization"
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
