using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using SparseArrays

module HTMTest
 using Test
 include("../src/common.jl")
 import Random.seed!

#function test_denseSynapses()
  seed!(0)
  inputDims= (4,5);
  spDims= (2,3);
  synapses= DenseSynapses(inputDims, spDims, rand);

  # Test access/modify patterns
  begin
    display(synapses[(2,2),(1,3)])
    @test synapses[(2,2),(1,3)] == synapses.data[6,5]
    @test_throws ErrorException synapses[(1:3,3:end),(1,end)]
    @test synapses[(1:3,3:5),(1,3)] == synapses.data[[9:11,13:15,17:19],5]
    @test synapses[(3,4),(:,2:3)] == synapses.data[15,[3:4,5:6]]
    #synapses[(3,4),(:,2:3)]= [1 2; 3 4]
    #@test synapses[(3,4),(:,2:3)] == synapses.data[3,4,:,:]
  end

  # Test array indices
  x= [(2,1), (4,5)]
  y= [(2,3), (1,1), (2,2)]
  begin
    display(synapses[x,y])
    synapses[x,y]= ones(UInt8, 2,3)
    display(synapses[x,y])
  end

  # aaaand... index iterators!
  begin
    ix= (i for i in x)
    iy= (i for i in y)
    display(synapses[ix,iy])
    synapses[ix,iy]= ones(UInt8, 2,3)
    display(synapses[ix,iy])
  end
#end
#test_denseSynapses()


function test_sparseSynapses()
  # TODO compare results with ground truth
  seed!(0)
  inputDims= (100,50);
  spDims= (200,100);
  synapses= SparseSynapses(inputDims, spDims, (T,m,n)-> sprand(T,m,n,2e-2));
  display(nnz(synapses))

  begin
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
 end
#test_sparseSynapses()


end #module
