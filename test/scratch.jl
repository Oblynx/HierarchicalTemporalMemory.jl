using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
import Random.seed!
seed!(0)

includet("../src/common.jl")
includet("../src/SpatialPooler.jl")

#display(@benchmark sp= SpatialPoolerM.SpatialPooler())

sp= SpatialPoolerM.SpatialPooler(SpatialPoolerM.SPParams(
      (4,4),(8,8), input_potentialRadius=2))
