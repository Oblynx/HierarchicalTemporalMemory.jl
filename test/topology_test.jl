ENV["JULIA_DEBUG"] = "all"
using HierarchicalTemporalMemory, Test

# Test iteration over a hypercube
startP= (50,80)
radius= 30
hc1= Hypercube(startP,radius,(200,200));
a= [convert(NTuple{2,Int},i) for i in hc1]
reference= [i for i in zip(
    repeat(startP[1]-radius : startP[1]+radius,outer=2*radius+1),
    repeat(startP[2]-radius : startP[2]+radius,inner=2*radius+1))]
@test a == reference
