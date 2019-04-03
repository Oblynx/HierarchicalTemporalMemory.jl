using HTM
using Test

@testset "Topology" begin include("topology_test.jl") end
@testset "Synapses" begin include("synapses_test.jl") end
