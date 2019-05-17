# Iterator transformations, like filters, don't keep the length info. This wrapper allows
#   length info known programmatically to be used
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


# Iterate over the trues of a BitArray
struct Truesof
  b::BitArray
end
@inline Base.length(B::Truesof)= length(B.b)
@inline Base.eltype(::Type{Truesof})= Int
Base.iterate(B::Truesof, i::Int=1)= begin
  i= findnext(B.b, i)
  i === nothing ? nothing : (i, i+1)
end
Base.collect(B::Truesof)= collect(B.b)

sparse_foreach(f, s::SparseMatrixCSC,columnIdx)=
  foreach(Truesof(columnIdx)) do c
    ci= nzrange(s,c)
    f(s,ci,rowvals(s)[ci])
  end
sparse_map(f, s::SparseMatrixCSC,columnIdx)=
  map(Truesof(columnIdx)) do c
    ci= nzrange(s,c)
    f(s,ci,rowvals(s)[ci])
  end


# This version applies f elementwise and concatenates the results
# a: vector of size [Ncol*k], column-major
# b: vectors of size Ncol
macro percolumn(f,a,b,k,Ncol)
  esc(:( $f.(reshape($a,$k,$Ncol), $b') ))
end
# This version reduces a per column
macro percolumn(reduce,a,k,Ncol)
  esc(:( $reduce(reshape($a,$k,$Ncol),dims=1)|> vec ))
end
