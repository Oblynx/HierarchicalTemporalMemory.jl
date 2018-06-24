module Topology

using Common
using StaticArrays

export hypercube, wrapping_hypercube


# Rely on nupic.core/topology. The hypercube is not an precomputed array, but an iterator that can provide the next value
abstract type AbstractHypercube{N,T} end

# TODO need to make hypercube abstract
struct hypercube{N,T} <: AbstractHypercube{N,T}
  xᶜ::SVector{N,T}
  radius::UIntSP
  dims::SVector{N,T}
end
struct wrapping_hypercube{N,T} <: AbstractHypercube{N,T}
  xᶜ::SVector{N,T}
  radius::UIntSP
  dims::SVector{N,T}
end

struct overflowingVector{N,T}
  x::MVector{N,T}
  start::SVector{N,T}
  lims::SVector{N,T}
  dims::SVector{N,T}
end
overflowingVector(s::SVector{N,T}, l, d) where {N,T}= overflowingVector(MVector(s),s,l,d)

### Hypercube iterator ###

# Start at the "lower left" corner of the hypercube
Base.start(hc::hypercube{N,T}) where {N,T}=
    overflowingVector(max.(hc.xᶜ.-hc.radius, 0), min.(hc.xᶜ.+hc.radius,hc.dims.-1), hc.dims)
Base.start(hc::wrapping_hypercube{N,T}) where {N,T}=
    overflowingVector(hc.xᶜ.-hc.radius, hc.xᶜ.+hc.radius, hc.dims)
# Increase dim i, overflow to i+1
Base.next(::AbstractHypercube{N,T},x::overflowingVector{N,T}) where {N,T}= (x.x, inc!(x))
Base.done(::AbstractHypercube{N,T},x::overflowingVector{N,T}) where {N,T}= x.x == x.lims

Base.eltype(::Type{AbstractHypercube{N,T}}) where {N,T}= overflowingVector{N,T}
Base.length(hc::AbstractHypercube)= (2*hc.radius+1).^length(hc.dims)


### Utility ###

function inc!(x::overflowingVector)
  i= 1
  x.x[i] += 1
  while x.x[i] > x.lims[i]
    print(x.x[i])
    x.x[i]= x.start[i]
    i += 1
    x.x[i] += 1
  end
  return x
end

# Return x.x, but wrap around if <0 | >dims
function get(x::overflowingVector)
  underwrap= x.x.<0; overwrap= x.x.>=x.dims;
  wrapped_x= x.x
  wrapped_x[underwrap].= x.dims[underwrap] .+ x.x[underwrap]
  wrapped_x[overwrap].= x.x[overwrap] .- x.dims[overwrap]
  return wrapped_x
end

end #module
