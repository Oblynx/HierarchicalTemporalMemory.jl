using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
using CSV
using Printf
using Plots; gr()
import Random: seed!, bitrand
seed!(0)

include("../src/common.jl")
include("../src/SpatialPooler.jl")
include("../src/encoder.jl")
include("../src/decoder.jl")
include("../src/TemporalMemory.jl")
include("utils/utils.jl")

display_evaluation(t,sp,sp_activity,spDims)= println("t=$t")
process_data!(history_enc,history_SP,history_TMout,history_TMpred,
              history_decodedPred,
              tN,data,encParams,sp,tm,decoder)=
  for t in 1:tN
    z,a,power_bucket= _process_sp(t,tN,data,encParams,sp,display_evaluation)
    A,Π= _process_tm(t,tN, tm,a)
    prediction= predict!(decoder,Π,power_bucket)
    history_enc[:,t]= z; history_SP[:,t]= a;
    history_TMout[:,t]= A; history_TMpred[:,t]= Π;
    history_decodedPred[:,t]= prediction;
    #t%08==0 && plot_ts_similarEncSp(t,data.power_hourly_kw,
    #                                encOnlyIdx,spOnlyIdx,encANDspHistory)
  end

prediction_timesteps=1
inputDims= ((12,3,3).*25,)
colDims= (1024,)
cellϵcol= 10
sp= SpatialPooler(SPParams(
      map(sum,inputDims),colDims,
      input_potentialRadius=35,
      sp_local_sparsity=0.02,
      θ_potential_prob_prox=0.931,
      θ_stimulus_act=1,
      permanence⁺= 0.09,
      permanence⁻= 0.009,
      β_boost=5,
      T_boost=300,
      enable_local_inhibit=false,
      enable_boosting=true))
tm= TemporalMemory(TMParams(colDims,
      cellϵcol=cellϵcol,
      θ_stimulus_act=10,
      θ_stimulus_learn=9
     ))
Ncol= prod(colDims); Ncell= Ncol*cellϵcol
# Define input data
data,tN= read_gympower()
encParams= initenc_powerDay(data.power_hourly_kw, data.hour, data.is_weekend,
                 encoder_size=inputDims[1], w=(40,40,36))
decoder= SDRClassifier(Ncell,encParams.power_p.buckets,
                  α=0.07, buffer_length=prediction_timesteps)
# Histories
history_enc= falses(map(sum,inputDims)|>prod,tN)
history_SP= falses(Ncol,tN)
history_TMout=  falses(Ncell,tN)
history_TMpred= falses(Ncell,tN)
history_decodedPred= zeros(encParams.power_p.buckets,tN)

process_data!(history_enc,history_SP,history_TMout,history_TMpred,
    history_decodedPred,
    tN,data,encParams,sp,tm,decoder)
