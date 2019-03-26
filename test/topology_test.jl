using Logging;
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

include("../src/common.jl")
include("../src/topology.jl")

# Test iteration over a hypercube
startP= (5,8)
radius= 3
hc1= hypercube(startP,radius,(20,20));
a= [convert(NTuple{2,Int},i) for i in hc1]
reference= [i for i in zip(
    repeat(startP[1]-radius : startP[1]+radius,outer=2*radius+1),
    repeat(startP[2]-radius : startP[2]+radius,inner=2*radius+1))]
@test a == reference
