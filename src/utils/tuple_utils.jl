const VecTuple{N,T}= Union{NTuple{N,T}, Vector{NTuple{N,T}}}

# This is a bit inefficient. The more verbose implementation below is more efficient and
#   allows use of the internal expand!
#expand(I::Vector{NTuple{N,T}}) where {N,T}= [map(a->a[i], I) for i in 1:N]
expand(I::Vector{NTuple{N,T}}) where {N,T}= begin
    r= Vector{Vector{T}}(undef,N)
    expand!(r,I)
    return r
end
expand(I::NTuple{N,T}) where {N,T}= [I[i] for i in 1:N]
expand!(r,I::Vector{NTuple{N,T}}) where {N,T}= foreach(i-> (r[i]= map(a->a[i],I)), 1:N)
expand!(r,I::NTuple{N,T}) where {N,T}= foreach(i-> (r[i]= I[i]), 1:N)

# NOTE this could probably be a macro
# OPTIMIZE Less runtime cost?
joinTuples(x,y,z...)= (x..., joinTuples(y,z...)...)
joinTuples(x,y)= (x..., y...)
joinTuples(x)= x

cartesianIdx(iPre::VecTuple{N1,T},iPost::VecTuple{N2,T}) where {N1,N2,T<:Integer}= (
    vec( map( x->CartesianIndex(joinTuples(x...)), Iterators.product(iPre,iPost) ) )
        ::Vector{CartesianIndex{N1+N2}})

#using Lazy
#cartesianIdx(iPre::VecTuple{N1,T},iPost::VecTuple{N2,T}) where {N1,N2,T<:Integer}=
#    (@>> Iterators.product(iPre,iPost) begin
#      map( x->CartesianIndex(joinTuples(x...)) )
#      vec
#    end )::Vector{CartesianIndex{N1+N2}}

vecTuple_2_tupleVec(i::Vector{NTuple{N,Int}}) where N=
    NTuple{N,Vector{Int}}(expand(i))
vecTuple_2_tupleVec(i)= i
