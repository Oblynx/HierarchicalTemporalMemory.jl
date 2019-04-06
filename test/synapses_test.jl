using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using SparseArrays

module HTMTest
include("../src/common.jl")
import Random.seed!

# Test DenseSynapses
seed!(0)
inputDims= (4,5);
spDims= (2,3);
# Create a Synapse array with these dimensions
synapses= DenseSynapses(inputDims, spDims, rand);
# Test access/modify patterns
#@views begin
#  @test synapses[2,2,1,3] == -69
#  @test synapses[1:3,3:end,1,end] == [77 -50 -2; 70 -91 22; 53 -32 11]
#  @test synapses[3,4,:,:] == [-105 42 -32; 81 115 -43]
#  synapses[3,4,:,2:3].= [1 2; 3 4];
#  @test synapses[3,4,:,:] == [-105 1 2; 81 3 4]
#end

# Test SparseSynapses
# TODO compare results with ground truth
seed!(0)
inputDims= (100,50);
spDims= (200,100);
synapses= SparseSynapses(inputDims, spDims, (T,m,n)-> sprand(T,m,n,2e-4));
display(nnz(synapses))

@views begin
  display(synapses[2,2,1,3])
  display(synapses[1:3,3:end,1,end])
  display(synapses[3:4,3:8,5,:])
  display(synapses[3:4,3:6,5,1:2])
  synapses[3:4,3:6,5,1:2]= sprand(Int8, 8,2,1.)
  display(synapses[3:4,3:6,5,1:2])
end

display(synapses[3,3:8,5,:])

end #module
