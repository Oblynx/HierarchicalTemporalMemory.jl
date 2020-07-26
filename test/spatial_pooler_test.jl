ENV["JULIA_DEBUG"] = "HierarchicalTemporalMemory"
plot_enabled= false

using HierarchicalTemporalMemory, BenchmarkTools, CSV, Printf, Lazy, Test
using Plots; gr()
import Random.seed!
seed!(0)

include("utils/utils.jl")

display_evaluation(t,sp,sp_activity,spDims)= begin
  @info("t=$t")
  sparsity= count(sp_activity)/prod(spDims)*100


  # Evaluation metrics
  #@info "Sparsity: $(sparsity)"
  #histogram(sp.b.b)|> display
  #histogram(sp.synapses.Dₚ[sp.synapses.Dₚ.>0]|>Vector, yaxis=(:log10))|> display
  #heatmap(@> sp_activity reshape(64,32))|> display
  #heatmap(@> sp.b.a_Tmean reshape(64,32))|> display
  #heatmap(sp.synapses.Dₚ)|> display
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
    t%60==0 && plot_enabled &&
        plot_ts_similarEncSp(t,data.power_hourly_kw,
                             encOnlyIdx,spOnlyIdx,encANDspHistory)
  end

# Define Spatial Pooler
inputDims= ((14,6,4).*25,)
spDims= (2048,).÷1
#inputDims= (8,8)
#spDims= (12,12)
@info "creating Spatial Pooler"
sp= SpatialPooler(SPParams(
      szᵢₙ= map(sum,inputDims), szₛₚ=spDims,
      γ=1000,
      s=0.02,
      prob_synapse=0.15,
      θ_stimulus_activate=4,
      p⁺_01= 0.07,
      p⁻_01= 0.12,
      β=5,
      Tboost=400,
      enable_local_inhibit=false,
      enable_boosting=true))
# Define input data
data,tN= read_gympower("test_data/gym_power_benchmark.csv")
encParams= initenc_powerDay(data.power_hourly_kw, data.hour, data.is_weekend,
                 encoder_size=inputDims[1], w=(23,27,27))
# Histories
encHistory= falses(map(sum,inputDims)|>prod,tN)
spHistory= falses(spDims|>prod,tN)
encANDspHistory= Vector{NamedTuple{(:encANDsp,:Nenc),Tuple{Vector{Int},Int}}}(undef,tN)

@info("processing data")
process_data!(encHistory,spHistory,encANDspHistory, tN,data,encParams,sp)
total_overlap= [1; map(x->length(x.encANDsp), encANDspHistory[2:end]) ./
                   map(x->x.Nenc, encANDspHistory[2:end])]
#plot(total_overlap)|>display
early_totalOverlap= mean(total_overlap[170:337])
late_totalOverlap= mean(total_overlap[338:end])
@info @sprintf("Mean SP performance: [%.2f,%.2f]\n", early_totalOverlap, late_totalOverlap)

# If this isn't true, something's quite wrong with the model
@test early_totalOverlap >= 0.8 && late_totalOverlap >= 0.8