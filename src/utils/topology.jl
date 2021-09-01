"""
Hypercube iterates over a hypercube of radius γ around xᶜ, bounded inside the space {1..sz}ᴺ.

# Examples
```jldoctest
julia> hc= Hypercube((3,3),1,(10,10));

julia> foreach(println, hc)
(2, 2)
(3, 2)
(4, 2)
(2, 3)
(3, 3)
(4, 3)
(2, 4)
(3, 4)
(4, 4)
```
"""
struct Hypercube{N}
  "xᶜ are the center coordinates"
  xᶜ::NTuple{N,Int}
  "γ is the hypercube radius. Points < γ away from xᶜ belong to the hypercube"
  γ::Int
  "sz is the upper bound of the enclosing space"
  sz::NTuple{N,Int}
  indices::CartesianIndices{N}
end
Hypercube(xᶜ,γ,sz)= Hypercube(xᶜ,γ,sz, start(xᶜ,γ,sz))

# Hypercube implements Iterator interface
start(xᶜ,γ,sz)= CartesianIndices(map( (a,b)-> a:b,
                    max.(xᶜ .- γ, 1),
                    min.(xᶜ .+ γ, sz) ))
Base.iterate(hc::Hypercube)= begin
  i= iterate(hc.indices)
  !isnothing(i) ? (i[1].I,i[2]) : nothing
end
Base.iterate(hc::Hypercube{N}, state) where N= begin
  i= Base.iterate(hc.indices, state)::Union{Nothing, Tuple{CartesianIndex{N}, CartesianIndex{N}}}
  !isnothing(i) ? (i[1].I,i[2]) : nothing
end
#Base.eltype(hc::Hypercube)= eltype(hc.indices)
Base.length(hc::Hypercube)= length(hc.indices)
Base.size(hc::Hypercube)= size(hc.indices)

# Good first approximation!
"""
Hypersphere is approximated with a Hypercube for simplicity

See also: [`Hypercube`](@ref)
"""
const Hypersphere{N}= Hypercube{N}

# Create a hypercube that wraps around the edges of the enclosing space
function wrapping_hypercube(xᶜ::NTuple{N,T},radius::Int,dims::NTuple{N,T}) where {N,T}
  xᶜ= convert(NTuple{N,UIntSP},xᶜ)
  dims= convert(NTuple{N,UIntSP},dims)
  wrapping_hypercube(xᶜ,radius,dims, startWrapping(xᶜ,radius,dims))
end

# BUG Wrapping can't work with a single CartesianIndices! It needs 2/4 of them!
#   from UP -> DIM, 0 -> DOWN !!!
startWrapping(xᶜ::NTuple{N,T},radius::T,dims::NTuple{N,T}) where {N,T}= begin
    CartesianIndices( map((a,b)-> a:b,
      wrapUnder.(xᶜ .- Int(radius), dims),   # BUG wrapUnder does smt funky, should return 10
      wrapOver.(xᶜ .+ Int(radius), dims)))
    end

wrapOver(a::T, lim::T) where T= a>lim ? a-lim : a
wrapUnder(a::T, lim::T) where T= a>lim ? lim-(typemax(T)-a)-T(1) : a
