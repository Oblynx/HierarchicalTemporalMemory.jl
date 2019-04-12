const VecTuple{N,T}= Union{NTuple{N,T}, Vector{NTuple{N,T}}}

expand(I::Vector{NTuple{N,T}}) where {N,T}= (map(a->a[i], I) for i in 1:N)
expand(I::NTuple{N,T}) where {N,T}= (I[i] for i in 1:N)

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
