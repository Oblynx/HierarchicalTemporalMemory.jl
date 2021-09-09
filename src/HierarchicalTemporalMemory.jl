module HierarchicalTemporalMemory

using SparseArrays, Parameters
using Lazy: @>, @>>
import Setfield: @set
import ImageFiltering: mapwindow, imfilter!, Fill
import Random: rand!, randsubseq!, randperm
import LinearAlgebra: Adjoint
import Statistics: mean, median, quantile
import StatsBase: countmap
import Chain: @chain

# Type aliases

const Option{T}= Union{T,Nothing}
const Maybe{T}= Union{T,Missing}
const VecInt{T<:Integer}= Union{Vector{T}, T}
"𝕊𝕢 is the type of connection permanences, defining their quantization domain"
const 𝕊𝕢= UInt8
"𝕊𝕢range is the domain of connection permanence quantization"
const 𝕊𝕢range= 𝕊𝕢(0):typemax(𝕊𝕢)

"Type of neuron layer activations"
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
include("utils/topology.jl")

# Algorithm imports

include("algorithm_parameters.jl")
include("dynamical_systems.jl")
include("SpatialPooler.jl")
include("TemporalMemory.jl")
include("Region.jl")

export Hypercube, Hypersphere
export SpatialPooler, SPParams
export TemporalMemory, TMParams
export Region
export step!

# Maybe move encoders to another package, as they're many and independent from the core algorithms?
# TODO create extensible encoder interface
# encode(:arithmetic,...), encode(:powerday,...) etc
include("encoder.jl")
export encode_simpleArithmetic, initenc_simpleArithmetic,
  encode_powerDay, initenc_powerDay

# TODO same for decoders
include("decoder.jl")
export SDRClassifier, predict!, reverse_simpleArithmetic

end # module
