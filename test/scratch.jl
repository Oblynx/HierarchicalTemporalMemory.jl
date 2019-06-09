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

inputDims= (800,)
colDims= (1000,)
cellϵcol= 10
sp= SpatialPooler(SPParams(inputDims,colDims))
z= bitrand(inputDims)
a= sp_activation(sp.proximalSynapses,sp.φ.φ,sp.b,z,colDims,sp.params)

#Π= bitrand(cellϵcol*prod(colDims))
tm= TMm.TemporalMemory(TMm.TMParams(colDims,
        cellϵcol=cellϵcol,
        θ_stimulus_activate=1,
        θ_stimulus_learn=0
      ),Nseg_init= prod(colDims)*cellϵcol)

A,B= TMm.tm_activation(a,tm.previous.Π,tm.params)
Π,_= TMm.tm_prediction(tm.distalSynapses,B,A,tm.params)

D= TMm.connected(tm.distalSynapses)
CS= TMm.cellXseg(tm.distalSynapses)

TMm.step!(tm,a)

#display(@benchmark TMm.tm_prediction(tm.distalSynapses,B,A,tm.params) )
#display(@benchmark TMm.step!(tm,a) )
