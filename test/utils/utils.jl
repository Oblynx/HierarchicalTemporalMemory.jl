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
  data= CSV.read("test/test_data/gym_power_benchmark.csv")
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
  topIdx= @> (sdrHist[:,end] .& sdrHist[:,1:end-1]) sum(dims=1) vec partialsortperm(1:k,rev=true)
  (sdrHist[:,topIdx], topIdx)
end


function plot_ts_similarEncSp(ts_plot,encOnly,spOnly,encspOverlapHistory,timestep)
end
