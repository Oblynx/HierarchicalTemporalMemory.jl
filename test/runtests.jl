ENV["JULIA_DEBUG"] = "HierarchicalTemporalMemory"
using HierarchicalTemporalMemory, Test

const GROUP = get(ENV, "GROUP", "All")
global plot_enabled= false

@testset "Topology" begin include("topology_test.jl") end
if GROUP == "ALL" || GROUP == "SpatialPooler"
  @testset "Spatial Pooler" begin
    include("spatial_pooler_test.jl")
  end
end
if GROUP == "ALL" || GROUP == "TemporalMemory"
  @testset "Temporal Memory" begin
    include("temporal_memory_test.jl")
  end
end