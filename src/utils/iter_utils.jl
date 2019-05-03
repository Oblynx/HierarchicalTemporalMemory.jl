# Iterator transformations, like filters, don't keep the length info. This wrapper allows
#   length info known programmatically to be used
struct LengthfulIter{T}
  iter
  n::Int
end
@inline Base.length(li::LengthfulIter)= li.n
@inline Base.iterate(li::LengthfulIter)= Base.iterate(li.iter)
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

sparse_map!(s::SparseMatrixCSC, a,f!,args...)=
    for c in findall(a)
        ci= nzrange(s,c)
        input_i= rowvals(s)[ci]
        f!(s,ci,input_i,args...)
    end
