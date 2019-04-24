using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
import Random.seed!
seed!(0)

includet("../src/common.jl")
includet("../src/SpatialPooler.jl")

#display(@benchmark sp= SpatialPoolerM.SpatialPooler())
inputDims= (16,16)
spDims= (64,64)
sp= SpatialPoolerM.SpatialPooler(SpatialPoolerM.SPParams(
      inputDims,spDims, input_potentialRadius=3))

activity= falses(prod(inputDims))
activity[rand(1:prod(inputDims),prod(inputDims)÷2)].= true
SpatialPoolerM.step!(sp,activity)
