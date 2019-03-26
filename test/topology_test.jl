using Logging;
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

#using Juno
using BenchmarkTools
using Traceur
#using Profile; Profile.init(;n=Int(5e6),delay=0.0005)
include("../src/common.jl")
include("../src/topology.jl")

hc1= hypercube((5000,8000),1000,(20000,20000));

f()= begin
  for i in hc1
    #display(i)
    i
  end
end

#@code_warntype debuginfo=:source iterate(hc1)
@time f()
