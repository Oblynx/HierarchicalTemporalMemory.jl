_process_sp(t,tN,signal,encParams,sp,display_evaluation=identity)= begin
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


plot_ts_similarEncSp(t,ts,encOnly,spOnly,encANDspHistory,scene::Scene=Scene())=
    t>1 ? _plot_ts_similarEncSP(scene,t,ts,encOnly,spOnly,encANDspHistory) : nothing
function _plot_ts_similarEncSP(scene,t,ts,encOnly,spOnly,encANDspHistory)
  graph_ts()= begin
    axislims= FRect(1, 0.9minimum(ts), length(ts), 1.05maximum(ts)-0.9minimum(ts))
    graph_ts= lines(ts, color=:blue, limits=axislims)
    scatter!(graph_ts, encOnly, ts[encOnly], markersize=18, alpha=0.8, color=:red)
    scatter!(graph_ts, spOnly, ts[spOnly], markersize=18, alpha=0.8, color=:yellow)
    scatter!(graph_ts, encANDspHistory[t][1], ts[encANDspHistory[t][1]], markersize=18,
              alpha=0.8, color=:green)
    lines!(graph_ts,[t,t],[minimum(ts),maximum(ts)], limits=axislims)
    lgd= legend([graph_ts[2],graph_ts[3],graph_ts[4],graph_ts[5]],
                ["power", "encoding only", "SP only", "overlapping"],
                camera=campixel!, raw=true)
    graph_ts= vbox(graph_ts,lgd)
    return graph_ts
  end
  graph_ovp(overlapFraction)= begin
    axislims= FRect(1,0,length(ts),101)
    graph_ovp= lines(1:t,overlapFraction*100, linestyle=:dash, color=:blue, limits=axislims)
    scatter!(graph_ovp, 1:t,overlapFraction*100, markersize=8, alpha=0.2, transparency=true,
             strokewidth=3.0, color=:red, limits=axislims)
    #ylabel="overlap%",ylims=(0,100),xlims=(1,length(ts)))
    return graph_ovp
  end
  overlapFraction= map(x->length(x.encANDsp)/x.Nenc, encANDspHistory[1:t])
  overlapFraction[isnan.(overlapFraction)].= 1.0
  #t1="Spatial Pooler mapping property evaluation"
  #t2="Percentage of overlapping encoder and SP SDRs"
  scene= hbox(graph_ovp(overlapFraction), graph_ts())|> display
  scene
end
