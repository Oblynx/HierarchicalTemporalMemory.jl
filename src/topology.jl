module Topology

# Rely on nupic.core/topology. The hypercube is not an precomputed array, but an iterator that can provide the next value
struct hypercube
  xᶜ::IntSP
  dims::Tuple{Vararg{UIntSP}}
  radius::UIntSP
end

function hypercube(xᶜ,length,dim)
  
end

Base.start(hc::hypercube)= 
Base.next(hc::hypercube)= 
Base.done(hc::hypercube)= 
Base.eltype(::Type{hypercube})= IntSP
Base.length(hc::hypercube)= (2*hc.radius+1).^length(hc.dims)

function wrapping_hypercube(xᶜ,length,dim)
end
end
