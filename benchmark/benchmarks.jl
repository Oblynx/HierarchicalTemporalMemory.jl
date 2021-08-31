using HierarchicalTemporalMemory, BenchmarkTools, CSV, Setfield, DataFrames
import Random.seed!
seed!(0)

include("setup.jl")

SUITE = BenchmarkGroup()
SUITE["SP"] = BenchmarkGroup()
SUITE["TM"] = BenchmarkGroup()

sp, refTM, data, encode, decoder= setupHTMexperiment()
z,_= encode(data,1)

seed!(0)
let grp= SUITE["SP"]
  # Run 1 iteration of SP adaptation repeatedly
  grp["1 iteration, global inhibit"]= @benchmarkable step!(sp,z)
  grp["1 iteration, local inhibit"]= @benchmarkable step!($(@set sp.params.enable_local_inhibit= true) ,z)
end

seed!(0)
let grp= SUITE["TM"]
  tN= size(data,1)
  a= Vector{sp(z)|>typeof}(undef,tN)
  for t= 1:tN
    z,_= encode(data,t)
    a[t]= step!(sp,z)
  end
  # The TM grows new dendrites/synapses at every step, and it will try to grow more
  # if the input is random. So try giving it reasonable input sequences.
  grp["first 100 steps"]= @benchmarkable for t= 1:100
      step!(tm,$a[t])
    end setup=( tm= deepcopy($refTM) )

  for t= 1 : tN-100
    step!(refTM,a[t])
  end
  grp["last 100 steps"]= @benchmarkable for t= $tN-99:$tN
      step!(tm,$a[t])
    end setup=( tm= deepcopy($refTM) )
end

#results= run(SUITE, verbose=true, seconds=20)