"""
Iterator transformations, like filters, don't keep the length info.
`LengthfulIter` is a wrapper that allows length info known programmatically to be used.
"""
struct LengthfulIter{T,IterT}
  iter::IterT
  n::Int
end
LengthfulIter{T}(iter::IterT,n) where {T,IterT}= LengthfulIter{T,IterT}(iter,n)
@inline Base.length(li::LengthfulIter)= li.n
@inline Base.iterate(li::LengthfulIter)=    Base.iterate(li.iter)
@inline Base.iterate(li::LengthfulIter, s)= Base.iterate(li.iter,s)
@inline Base.eltype(::Type{LengthfulIter{T}}) where T= T
@inline Base.collect(li::LengthfulIter{T}) where T= _collect(li.iter,li.n,T)
# Stolen from @array.jl#600
function _collect(itr::Base.Generator,sz::Int, elT)
  _array_for(::Type{T}, itr) where {T} = Vector{T}(undef, sz)
  y= iterate(itr)
  y === nothing && return _array_for(elT, itr.iter)
  v1, st = y
  Base.collect_to_with_first!(_array_for(typeof(v1), itr.iter), v1, itr, st)
end
_collect(itr,n,elT)= Base.collect(itr)

"""
Iterate over the trues of a BitArray

# Examples
```jldoctest
julia> using Random; seed!(5);
julia> b=bitrand(5)
5-element BitArray{1}:
  true
 false
 false
  true
  true
julia> foreach(i-> print(string(i)*" "), Truesof(b))
1 4 5
```
"""
struct Truesof
  b::BitArray
end
@inline Base.length(B::Truesof)= count(B.b)
@inline Base.eltype(::Type{Truesof})= Int
Base.iterate(B::Truesof, i::Int=1)= begin
  i= findnext(B.b, i)
  i === nothing ? nothing : (i, i+1)
end
Base.collect(B::Truesof)= collect(B.b)

"""
    sparse_foreach(f, s::SparseMatrixCSC,columnIdx)

Iterate SparseMatrix `s` and apply `f` columnwise (`f(s,nzrange,rowvals)`)
"""
sparse_foreach(f, s::SparseMatrixCSC,columnIdx)=
  foreach(Truesof(columnIdx)) do c
    ci= nzrange(s,c)
    f((@view nonzeros(s)[ci]),rowvals(s)[ci])
  end
sparse_map(f, s::SparseMatrixCSC,columnIdx)=
  map(Truesof(columnIdx)) do c
    ci= nzrange(s,c)
    f((@view nonzeros(s)[ci]),rowvals(s)[ci])
  end

"""
@percolumn(f,a,b,k,Ncol)

Macro to apply `f` elementwise and concatenate the results.
- `a`: vector of size [`Ncol`*`k`], column-major
- `b`: vectors of size `Ncol`
"""
macro percolumn(f,a,b,k)
  esc(:( $f.(reshape($a,$k,:), $b') ))
end
"""
@percolumn(reduce,a,k,Ncol)

Macro to `reduce` `a` per column.
"""
macro percolumn(reduce,a,k)
  esc(:( $reduce(reshape($a,$k,:),dims=1)|> vec ))
end
"""
    bitarray(dims, idx)

Create a bitarray with `true` only at `idx`.
"""
function bitarray(idx,dims)
  r= falses(dims)
  r[idx].= true
  return r
end
function bitarray(idx::Int,dims)
  r= falses(dims)
  r[idx]= true
  return r
end
padfalse(b::BitArray,dim)= [b;falses(dim-length(b))]
padfalse(b::Vector{T},dim) where T= [b;zeros(T,dim-length(b))]


"""
`Sequence(;δ,init)` is an easy way to define sequences with transition function `δ` and starting condition `init`
as an iterator.

# Examples

Fibonacci sequence:
```jldoctest exp; setup= :(import IterTools, Lazy; const HTM=HierarchicalTemporalMemory)
fibonacci_δ(a,b)= b, a+b
fibonacci_init= 0,1
Lazy.@as _1 HTM.Sequence(fibonacci_δ, fibonacci_init) IterTools.take(_1, 13) foreach(display, _1)

# output
0
1
1
2
3
5
8
13
21
34
55
89
144
```

Factorial sequence:
```jldoctest exp
factorial_δ(a,b)= a*b, b+1
factorial_init= 1,1
Lazy.@as _1 HTM.Sequence(factorial_δ, factorial_init) IterTools.take(_1, 13) foreach(display, _1)

# output
1
1
2
6
24
120
720
5040
40320
362880
3628800
39916800
479001600
```
"""
struct Sequence{F <: Function, I}
  δ::F
  init::I
  Sequence(δ::F,init::I) where {F,I}= new{F,I}(δ,init)
  Sequence(;δ::F,init::I) where {F,I}= new{F,I}(δ,init)
end

Base.iterate(s::Sequence) = iterate(s, s.init)
Base.iterate(s::Sequence, state) = state[1], s.δ(state...)
Base.IteratorSize(::Sequence) = Base.SizeUnknown()
Base.IteratorEltype(::Sequence) = Base.EltypeUnknown()
