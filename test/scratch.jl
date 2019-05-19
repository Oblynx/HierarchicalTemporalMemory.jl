using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
using Plots
import Random: seed!, bitrand
seed!(0)

include("../src/common.jl")
include("../src/SpatialPooler.jl")
include("../src/encoder.jl")
include("../src/TemporalMemory.jl")

inputDims= (20,)
colDims= (600,)
cellϵcol= 8
sp= SpatialPooler(SPParams(inputDims,colDims))
z= bitrand(inputDims)
a= sp_activation(sp.proximalSynapses,sp.φ.φ,sp.b,z,colDims,sp.params)

#Π= bitrand(cellϵcol*prod(colDims))
tm= TMm.TemporalMemory(TMm.TMParams(colDims,
        cellϵcol=cellϵcol, Nseg=prod(colDims)*cellϵcol*2,
        θ_stimulus_act=1,
        θ_stimulus_learn=0
      ))

A,B= TMm.tm_activation(a,tm.Π,tm.params)
Π,_= TMm.tm_prediction(tm.distalSynapses,B,A,tm.params)
#display(@benchmark TMm.tm_activation(a,tm.Π,tm.params) )
display(@benchmark TMm.tm_prediction(tm.distalSynapses,B,A,tm.params) )

D= TMm.connected(tm.distalSynapses, tm.params.θ_permanence_dist)
CS= TMm.cellXseg(tm.distalSynapses)
