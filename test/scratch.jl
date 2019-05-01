using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
import Random.seed!
seed!(0)

include("../src/common.jl")
include("../src/SpatialPooler.jl")
include("../src/encoder.jl")

process_data(ts,signal,encParams,sp)=
  for t in ts
    activity,_= encode_simpleArithmetic(signal[t]; encParams...)
    sp_activity= SpatialPoolerM.step!(sp,activity)
    t%1000==0 && display_evaluation(t,sp,sp_activity,sp.params.spSize)
  end
display_evaluation(t,sp,sp_activity,spDims)= begin
  println("t=$t")
  sparsity= count(sp_activity)/prod(spDims)*100
  sparsity|> display

  #histogram(sp.b.b)|> display
  #histogram(sp.proximalSynapses.synapses[sp.proximalSynapses.synapses.>0])|> display

  #heatmap(@> sp_activity)|> display
  heatmap(@> sp.b.a_Tmean reshape(50,10))|> display
  #heatmap(sp.proximalSynapses.synapses)|> display
end

inputDims= (500,)
spDims= (500,)
sp= SpatialPoolerM.SpatialPooler(SpatialPoolerM.SPParams(
      inputDims,spDims,
      input_potentialRadius=6,
      T_boost=800,
      θ_stimulus_act=1,
      enable_local_inhibit=false,
      enable_boosting=true))

activity= falses(prod(inputDims))
activity[rand(1:prod(inputDims),prod(inputDims)÷2)].= true
SpatialPoolerM.step!(sp,activity)
sp_activity= SpatialPoolerM.sp_activation(sp.proximalSynapses,sp.φ.φ,sp.b,activity', sp.params.spSize,sp.params)

ts= 1:10000
f= 1 ./ [10 10.3 12.1]
signal= sum(sin.(2pi*f.*ts), dims=2) .+ 0.5*rand(ts|>length)
encParams= initenc_simpleArithmetic(signal,encoder_size=inputDims, buckets=16)
using Plots
process_data(ts,signal,encParams,sp)
