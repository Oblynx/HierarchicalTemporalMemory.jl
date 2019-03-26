# Rely on nupic.core/topology. The hypercube is not an precomputed array, but an iterator
# that can provide the next value
abstract type AbstractHypercube{N,T} end

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
hypercube(xᶜ::NTuple{N,T},radius,dims::NTuple{N,T}) where{N,T}=
    hypercube(SVector(xᶜ),UIntSP(radius),SVector(dims));
wrapping_hypercube(xᶜ::NTuple{N,T},radius,dims::NTuple{N,T}) where{N,T}=
    wrapping_hypercube(SVector(xᶜ),UIntSP(radius),SVector(dims));

struct overflowingVector{N,T}
  x::SVector{N,T}
  start::SVector{N,T}
  lims::SVector{N,T}
end
overflowingVector(x::SVector{N,T}, l) where {N,T}= overflowingVector(x,x,l)
overflowingVector(a::overflowingVector)= overflowingVector(a.x,a.start,a.lims)
overflowingVector(a::overflowingVector,xnew::SVector{N,T}) where {N,T}=
    overflowingVector(xnew,a.start,a.lims)

### Hypercube iterator ###

# Start at the "lower left" corner of the hypercube
start(hc::hypercube{N,T}) where {N,T}=
    overflowingVector(
      max.(hc.xᶜ .- hc.radius, 0),
      min.(hc.xᶜ .+ hc.radius,hc.dims.-1))
start(hc::wrapping_hypercube{N,T}) where {N,T}=
    overflowingVector(
      hc.xᶜ .- hc.radius,
      hc.xᶜ .+ hc.radius,
      hc.dims)

# Iterate over a Hypercube
const hypercubeIterateRet{N,T}= Tuple{ SVector{N,T}, Maybe{overflowingVector{N,T}} }
function Base.iterate(hc::AbstractHypercube{N,T},
                      x::overflowingVector{N,T}= start(hc)
                     ) where {N,T}
  x.x == x.lims ? nothing : (x.x, inc(x))
end
# Increase dim i, overflow to i+1
#Base.next(::AbstractHypercube{N,T},x::overflowingVector{N,T}) where {N,T}= (x.x, inc!(x))
#Base.done(::AbstractHypercube{N,T},x::overflowingVector{N,T}) where {N,T}= x.x == x.lims

Base.eltype(::Type{AbstractHypercube{N,T}}) where {N,T}= overflowingVector{N,T}
Base.length(hc::AbstractHypercube)= (2*hc.radius+1).^length(hc.dims)


### Utility ###

#function inc!(x::overflowingVector)
#  i= 1
#  x.x[i] += 1
#  while x.x[i] > x.lims[i]
#    #print(x.x[i])
#    x.x[i]= x.start[i]
#    i += 1
#    x.x[i] += 1
#  end
#  return x
#end

function inc(x::overflowingVector)
  i= 1
  xn= setindex(x.x, x.x[i]+1,i);
  while xn[i] > x.lims[i]
    xn= setindex(xn, x.start[i],i)
    i+= 1
    xn= setindex(xn, xn[i]+1,i)
  end
  return overflowingVector(x,xn)
end


# Return x.x, but wrap around if <0 | >dims
function get(x::overflowingVector)
  underwrap= x.x.<0; overwrap= x.x.>=x.dims;
  wrapped_x= x.x
  wrapped_x[underwrap].= x.dims[underwrap] .+ x.x[underwrap]
  wrapped_x[overwrap].= x.x[overwrap] .- x.dims[overwrap]
  return wrapped_x
end
