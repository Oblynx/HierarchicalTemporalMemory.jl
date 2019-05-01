abstract type AbstractHypercube{N,T} end

struct hypercube{N,T<:Integer} <: AbstractHypercube{N,T}
  xᶜ::NTuple{N}
  radius::T
  dims::NTuple{N}
  indices::CartesianIndices{N}
end
struct wrapping_hypercube{N,T} <: AbstractHypercube{N,T}
  xᶜ::NTuple{N,T}
  radius::Int
  dims::NTuple{N,T}
  indices::CartesianIndices{N}
end
function hypercube(xᶜ::NTuple{N},radius,dims::NTuple{N}) where {N}
  hypercube(xᶜ,radius,dims, start(xᶜ,radius,dims))
end
function wrapping_hypercube(xᶜ::NTuple{N,T},radius::Int,dims::NTuple{N,T}) where {N,T}
  xᶜ= convert(NTuple{N,UIntSP},xᶜ)
  dims= convert(NTuple{N,UIntSP},dims)
  wrapping_hypercube(xᶜ,radius,dims, startWrapping(xᶜ,radius,dims))
end

# Good first approximation!
const hypersphere{N,T}= hypercube{N,T}
hypersphere(xᶜ::NTuple{N},radius,dims::NTuple{N}) where {N}= hypercube(xᶜ,radius,dims)

# Start at the "lower left" corner of the hypercube
start(xᶜ::NTuple{N},radius,dims::NTuple{N}) where {N}=
    CartesianIndices( map((a,b)-> a:b,
      max.(xᶜ .- Int(radius), 1),
      min.(xᶜ .+ Int(radius), dims)))

# BUG Wrapping can't work with a single CartesianIndices! It needs 2/4 of them!
#   from UP -> DIM, 0 -> DOWN !!!
startWrapping(xᶜ::NTuple{N,T},radius::T,dims::NTuple{N,T}) where {N,T}= begin
    CartesianIndices( map((a,b)-> a:b,
      wrapUnder.(xᶜ .- Int(radius), dims),   # BUG wrapUnder does smt funky, should return 10
      wrapOver.(xᶜ .+ Int(radius), dims)))
    end

wrapOver(a::T, lim::T) where T= a>lim ? a-lim : a
wrapUnder(a::T, lim::T) where T= a>lim ? lim-(typemax(T)-a)-T(1) : a


# Iterate over a Hypercube
Base.iterate(hc::AbstractHypercube)= iterate(hc.indices)
Base.iterate(hc::AbstractHypercube,state)= iterate(hc.indices,state)

Base.eltype(hc::AbstractHypercube)= eltype(hc.indices)
Base.length(hc::AbstractHypercube)= length(hc.indices)
Base.size(hc::AbstractHypercube)= size(hc.indices)