using Logging;
ENV["JULIA_DEBUG"] = "all"
logger = ConsoleLogger(stdout, Logging.Debug);

using StaticArrays
using Juno
using Profile; Profile.init(;n=Int(5e6),delay=0.0005)
include("../src/common.jl")
include("../src/topology.jl")

hc1= hypercube((500,800),500,(2000,2000));

f()= begin
  for i in 1:20
    for i in hc1
      #display(i)
      i
    end
  end
end

@code_warntype debuginfo=:source iterate(hc1)
@time f()
