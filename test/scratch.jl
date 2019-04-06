using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

include("../src/common.jl")

synapses= SparseSynapses((10,10), (10,10), (T,m,n)-> sprand(T,m,n,6e-2))
