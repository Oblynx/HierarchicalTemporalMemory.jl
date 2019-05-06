_process_sp(t,tN,data,encParams,sp,display_evaluation=identity)= begin
  # z: encoder activation
  z,_= encode_powerDay(data.power_hourly_kw[t], data.hour[t], data.is_weekend[t];
                       encParams...)
  # a: SP activation
  a= step!(sp,z)

  t%(tN÷10)==0 && display_evaluation(t,sp,a,sp.params.spSize)
  (z,a)
end
identity(a...)= a
read_gympower()= begin
  data= CSV.read("test/test_data/gym_power_benchmark.csv", allowmissing=:auto)
  ((power_hourly_kw= data.power_hourly_kw,
    hour= data.hour,
    is_weekend= data.is_weekend
   ), size(data,1))
end
"""
Find the top-k% most similar SDRs to the last one from the entire history.
"""
top_similar_sdr(sdrHist,k)= begin
  k= size(sdrHist,2)==1 ? 0 : ceil(Int,k/100*size(sdrHist,2))
  # Shame: I can't find ANY high-level construct to even approach the efficiency of this!
  overlap= zeros(Int32,size(sdrHist,2)-1)
  for t in 1:length(overlap) for i in 1:size(sdrHist,1)
      overlap[t]+= sdrHist[i,end] & sdrHist[i,t] end end
  topIdx= @> overlap partialsortperm(1:k,rev=true)
  (sdrHist[:,topIdx], topIdx)
end


plot_ts_similarEncSp(t,ts,encOnly,spOnly,encANDspHistory)=
    if t>1 _plot_ts_similarEncSP(t,ts,encOnly,spOnly,encANDspHistory)
    end
function _plot_ts_similarEncSP(t,ts,encOnly,spOnly,encANDspHistory)
  graph_ts()= begin
    graph_ts= plot(ts, label="power", dpi=192, ylims=(0.9minimum(ts),1.05maximum(ts)),
              xlims=(1,1.3length(ts)))
    scatter!(graph_ts, encOnly, ts[encOnly], label="encoding only")
    scatter!(graph_ts, spOnly, ts[spOnly], label="SP only")
    scatter!(graph_ts, encANDspHistory[t][1], ts[encANDspHistory[t][1]],
              label="overlapping", legendfontsize=6)
    vline!(graph_ts,[t], label="")
    title!(graph_ts, "Spatial Pooler mapping property evaluation", titlefont=font(10))
    return graph_ts
  end
  graph_ovp(overlapFraction)= begin
    graph_ovp= plot(1:t,overlapFraction*100, label="", linestyle=:dash, shape=:circle,
        msize=3, mcolor=:red, mscolor=:green, dpi=192,
        ylabel="overlap%",ylims=(-1,102),xlims=(1,1.3length(ts)))
    title!(graph_ovp, "Percentage of overlapping encoder and SP SDRs", titlefont=font(10))
    return graph_ovp
  end
  overlapFraction= map(x->length(x.encANDsp)/x.Nenc, encANDspHistory[1:t])
  overlapFraction[isnan.(overlapFraction)].= 1.0
  plot(graph_ts(),graph_ovp(overlapFraction), layout=(2,1))|> display
end
