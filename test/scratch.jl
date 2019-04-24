using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
import Random.seed!
seed!(0)

includet("../src/common.jl")
includet("../src/SpatialPooler.jl")

#display(@benchmark sp= SpatialPoolerM.SpatialPooler())
inputDims= (10,10)
spDims= (64,64)
sp= SpatialPoolerM.SpatialPooler(SpatialPoolerM.SPParams(
      inputDims,spDims,
      input_potentialRadius=4,
      n_active_perinhibit=10,
      θ_stimulus_act=1))

activity= falses(prod(inputDims))
activity[rand(1:prod(inputDims),prod(inputDims)÷2)].= true
SpatialPoolerM.step!(sp,activity)
#sp_activity= SpatialPoolerM.sp_activation(sp.proximalSynapses.synapses,sp.φ,sp.b,activity', sp.params.spSize,sp.params)

# Show synapse adaptation!
#using Plots
#for t= 1:100
#  activity= falses(prod(inputDims))
#  activity[rand(1:prod(inputDims),prod(inputDims)÷2)].= true
#  SpatialPoolerM.step!(sp,activity)
#  display(heatmap(sp.proximalSynapses.synapses))
#  sleep(0.05)
#end
