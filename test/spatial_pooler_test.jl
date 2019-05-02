using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);
using BenchmarkTools

module HTMt
using BenchmarkTools
using CSV
using Printf
using Plots; gr()
import Random.seed!
seed!(0)

include("../src/common.jl")
include("../src/SpatialPooler.jl")
include("../src/encoder.jl")
include("utils/utils.jl")

display_evaluation(t,sp,sp_activity,spDims)= begin
  println("t=$t")
  sparsity= count(sp_activity)/prod(spDims)*100
  sparsity|> display

  #histogram(sp.b.b)|> display
  #histogram(sp.proximalSynapses.synapses[sp.proximalSynapses.synapses.>0])|> display
  #heatmap(@> sp_activity reshape(64,32))|> display
  #heatmap(@> sp.b.a_Tmean reshape(64,32))|> display
  #heatmap(sp.proximalSynapses.synapses)|> display
end
process_data!(encHistory,spHistory,encANDspHistory,tN,data,encParams,sp)=
  for t in 1:tN
    z,a= _process_sp(t,tN,data,encParams,sp,display_evaluation)
    encHistory[:,t]= z; spHistory[:,t]= a
    # when were the most similar SDRs to z,a in history? These indices correspond to times
    _,similarEncIdx= top_similar_sdr(encHistory[:,1:t],10)
    _,similarSpIdx= top_similar_sdr(spHistory[:,1:t],10)
    encOnlyIdx= setdiff(similarEncIdx, similarSpIdx)
    spOnlyIdx= setdiff(similarSpIdx, similarEncIdx)
    encANDspHistory[t]= (encANDsp= intersect(similarEncIdx,similarSpIdx), Nenc= length(similarEncIdx))
    t%10==0 && plot_ts_similarEncSp(t,data.power_hourly_kw,
                                    encOnlyIdx,spOnlyIdx,encANDspHistory)
  end

# Define Spatial Pooler
inputDims= ((16*25,5*25,3*25),)
spDims= (2048,)
sp= SpatialPooler(SPParams(
      map(sum,inputDims),spDims,
      input_potentialRadius=6,
      sp_local_sparsity=0.02,
      θ_potential_prob_prox=0.15,
      θ_stimulus_act=1,
      permanence⁺= 0.05,
      permanence⁻= 0.008,
      β_boost=6,
      T_boost=400,
      enable_local_inhibit=false,
      enable_boosting=true))
# Define input data
data,tN= read_gympower()
encParams= initenc_powerDay(data.power_hourly_kw, data.hour, data.is_weekend,
                 encoder_size=inputDims[1], w=(21,27,27))
encHistory= falses(map(sum,inputDims)|>prod,tN)
spHistory= falses(spDims|>prod,tN)
encANDspHistory= Vector{NamedTuple{(:encANDsp,:Nenc),Tuple{Vector{Int},Int}}}(undef,tN)
process_data!(encHistory,spHistory,encANDspHistory, tN,data,encParams,sp)
total_overlap= [1; map(x->length(x.encANDsp), encANDspHistory[2:end]) ./
                   map(x->x.Nenc, encANDspHistory[2:end])]
#plot(total_overlap)|>display
@printf("Mean SP performance: [%.2f,%.2f]\n",
        mean(total_overlap[170:337]),mean(total_overlap[338:end]))
end #module
