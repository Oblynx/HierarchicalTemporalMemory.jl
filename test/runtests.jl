ENV["JULIA_DEBUG"] = "HierarchicalTemporalMemory"
using HierarchicalTemporalMemory, Test

@enum GROUPS All SpatialPooler TemporalMemory

const GROUP= try
  get(ENV, "GROUP", "All")|> Symbol|> eval
catch e
  error("ENV[\"GROUP\"]: Invalid value. Supported values: $(GROUPS|>instances)")
end
global plot_enabled= false

@testset "Topology" begin include("topology_test.jl") end
if GROUP == All || GROUP == SpatialPooler
  @testset "Spatial Pooler" begin
    include("spatial_pooler_test.jl")
  end
end
if GROUP == All || GROUP == TemporalMemory
  @testset "Temporal Memory" begin
    include("temporal_memory_test.jl")
  end
end