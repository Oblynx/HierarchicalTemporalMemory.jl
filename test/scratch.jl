using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

include("../src/common.jl")
include("../src/SpatialPooler.jl")

sp= SpatialPoolerM.SpatialPooler()
