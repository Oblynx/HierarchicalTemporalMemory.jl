using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools

include("../src/common.jl")
include("../src/SpatialPooler.jl")

#display(@benchmark sp= SpatialPoolerM.SpatialPooler())

@profiler sp= SpatialPoolerM.SpatialPooler()
