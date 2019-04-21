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
    @test synapses[(2,2),(1,3)] == synapses.data[inputDims[1]*1+2,spDims[1]*2+1]
    @test_throws ErrorException synapses[(1:3,3:end),(1,end)]
    @test synapses[(1:3,3:5),(1,3)] == synapses.data[vec(inputDims[1].*(2:4)'.+(1:3)), spDims[1]*2+1]
    @test synapses[(3,4),(:,2:3)] == synapses.data[inputDims[1]*3+3,
                                      vec(spDims[1].*(1:2)'.+(1:spDims[1]))]
    beforeMod= synapses.data[inputDims[1]*3+3,vec(spDims[1].*(1:2)'.+(1:spDims[1]))]
    synapses[(3,4),(:,2:3)]= reshape(1:(2*spDims[1]), spDims[1],2)
    @test (synapses[(3,4),(:,2:3)] == synapses.data[inputDims[1]*3+3,vec(spDims[1].*(1:2)'.+(1:spDims[1]))] &&
           synapses[(3,4),(:,2:3)] != beforeMod)
  end

  # Test array indices
  x= [(2,1), (4,5)]
  y= [(2,3), (1,1), (2,2)]
  begin
    synapses[x,y]= ones(UInt8, 2,3)
    @test (synapses[x,y] .== 1)|> all
  end

  # boolean indexing?
  begin
    connectedSyn= synapses .> UIntSP(100)
    @test synapses[connectedSyn] == synapses.data[connectedSyn]
  end

  # Test linear algebra
  begin
    a= rand(1,prod(inputDims))
    b= rand(prod(spDims))
    @test a*synapses == a*synapses.data
    @test synapses*b == synapses.data*b
  end

  # aaaand... index iterators!
  begin
    include("../src/topology.jl")
    ix= hypercube((2,2),1,inputDims)
    iy= (i for i in y)
    synapses[ix,iy]= 3*ones(UInt8, length(ix),length(iy))
    @test (synapses[ix,iy] .== 3)|> all
  end

  # Views
  begin
    iy= hypercube((2,2),1,spDims)
    beforeMod= synapses[x,iy]
    synapseView= @view synapses[x,iy]
    @test (synapseView == beforeMod)
    synapseView.= 5
    @test (synapseView .== 5)|> all
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
