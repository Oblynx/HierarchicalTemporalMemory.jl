ENV["JULIA_DEBUG"] = "HierarchicalTemporalMemory"
using HierarchicalTemporalMemory, Test

@enum GROUPS AllTests SpatialPoolerTest TemporalMemoryTest

const GROUP= try
  get(ENV, "GROUP", "AllTests")|> Symbol|> eval
catch e
  error("ENV[\"GROUP\"]: Invalid value. Supported values: $(GROUPS|>instances)\n Given: $e")
end
global plot_enabled= false

#using Aqua
#Aqua.test_all(HierarchicalTemporalMemory)

@testset "Topology" begin include("topology_test.jl") end
if GROUP == AllTests || GROUP == SpatialPoolerTest
  @testset "Spatial Pooler" begin
    include("spatial_pooler_test.jl")
  end
end
if GROUP == AllTests || GROUP == TemporalMemoryTest
  @testset "Temporal Memory" begin
    include("temporal_memory_test.jl")
  end
end