using Logging
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using BenchmarkTools
using CSV
using Printf
using StatsBase: median
#using Plots; gr()
import Random: seed!, bitrand
seed!(0)

include("../src/common.jl")
include("../src/SpatialPooler.jl")
include("../src/encoder.jl")
include("../src/decoder.jl")
include("../src/TemporalMemory.jl")
include("utils/utils.jl")

display_evaluation(t,sp,sp_activity,spDims)= println("t=$t")
process_data!(tN,data,encParams,sp,tm,decoder)=
  for t in 1:tN
    z,a,power_bucket= _process_sp(t,tN,data,encParams,sp,display_evaluation)
    A,Π,B= _process_tm(t,tN, tm,a)
    prediction= predict!(decoder,Π,power_bucket)
    likelyPred= reverse_simpleArithmetic(prediction,"mode",encParams.power_p)
    history_enc[:,t]= z;    history_SP[:,t]= a
    history_TMout[:,t]= A;  history_TMpred[:,t]= Π
    history_decodedPred[:,t]= prediction; history_likelyPred[t]= likelyPred

    global avg_burst= ((t-1)*avg_burst+count(B)/length(B))/t
  end

prediction_timesteps=1
inputDims= ((12,3,3).*25,)
colDims= (1548,)
cellϵcol= 12
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
      θ_stimulus_act=40,
      θ_stimulus_learn=37,
      synapseSampleSize=25,
      permanence⁺=0.07,
      permanence⁻=0.13
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
history_likelyPred= zeros(tN)
avg_burst= 0

process_data!(tN,data,encParams,sp,tm,decoder)

errormetric= mase(data.power_hourly_kw,history_likelyPred,prediction_timesteps)
display("Prediction MASE: $errormetric")

avg_TMout_sparsity= mapslices(x->count(x)./length(x),history_TMout,dims=1)'|>median
display(avg_TMout_sparsity)
display(avg_burst)
