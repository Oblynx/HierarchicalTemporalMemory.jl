using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
import Random.seed!
seed!(0)

include("../src/common.jl")
include("../src/SpatialPooler.jl")

#display(@benchmark sp= SpatialPoolerM.SpatialPooler())

sp= SpatialPoolerM.SpatialPooler(SpatialPoolerM.SPParams(
      UIntSP.((40,40)),UIntSP.((100,100)), input_potentialRadius=2))
