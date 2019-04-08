using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using SparseArrays

module HTMTest
using Test
include("../src/common.jl")
import Random.seed!
seed!(0)

# ## Test DenseSynapses

inputDims= (4,5);
spDims= (2,3);
# Create a Synapse array with these dimensions
synapses= DenseSynapses(inputDims, spDims, rand);
# Test access/modify patterns
@views begin
  @test synapses[2,2,1,3] == 0xbb
  @test synapses[1:3,3:end,1,end] == [0x4d 0xce 0xfe;0x46 0xa5 0x16;0x35 0xe0 0x0b]
  @test synapses[3,4,:,:] == [0x97 0x2a 0xe0;0x51 0x73 0xd5]
  synapses[3,4,:,2:3].= [1 2; 3 4]
  @test synapses[3,4,:,:] == [0x97 0x01 0x02;0x51 0x03 0x04]
end

# Test index-by-NTuple (coordinates)
# TODO compare results with ground truth
x= [(2,1), (4,5)]
y= [(2,3), (1,1), (2,2)]
display(synapses[x,y])
synapses[x,y]= ones(UInt8, 2,3)
display(synapses[x,y])


# ## Test SparseSynapses

# TODO compare results with ground truth
seed!(0)
inputDims= (100,50);
spDims= (200,100);
synapses= SparseSynapses(inputDims, spDims, (T,m,n)-> sprand(T,m,n,2e-2));
display(nnz(synapses))

@views begin
  # Scalar setindex
  display(synapses[2,2,1,3])
  synapses[2,2,1,3]= SynapsePermanenceQuantization(1)
  display(synapses[2,2,1,3])

  # Non-scalar getindex
  display(synapses[1:3,3:end,1,end])
  display(synapses[3:4,3:8,5,:])

  # Non-scalar setindex. Can match either the extrinsic or the intrinsic dims
  display(synapses[3:4,3:6,5,1:2])
  synapses[3:4,:,5,1:2]= rand(SynapsePermanenceQuantization, 2,50,1,2)
  display(synapses[3:4,3:6,5,1:2])
  synapses[3:4,:,5,1:2]= sprand(SynapsePermanenceQuantization, 100,2,.5)
  display(synapses[3:4,3:6,5,1:2])

  # Colon setindex
  synapses[:,1,1,1]= rand(SynapsePermanenceQuantization, 100)
end

# Test index-by-NTuple (coordinates)
# TODO compare results with ground truth
x= [(2,1), (4,5)]
y= [(2,3), (1,1), (2,2)]
display(synapses[x,y])
synapses[x,y]= ones(UInt8, 2,3)
display(synapses[x,y])

end #module
