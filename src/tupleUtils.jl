const VecTuple{N,T}= Union{NTuple{N,T}, Vector{NTuple{N,T}}}

expand(I::Vector{NTuple{N,T}}) where {N,T}= (map(a->a[i], I) for i in 1:N)
expand(I::NTuple{N,T}) where {N,T}= (I[i] for i in 1:N)

joinTuples(x)= x
joinTuples(x,y)= (x..., y...)
joinTuples(x,y,z...)= (x..., joinTuples(y,z...)...)

cartesianIdx(iPre::VecTuple{N,T},iPost::VecTuple{N,T}) where {N,T<:Integer}=
    map(x->CartesianIndex(joinTuples(x...)), Iterators.product(iPre,iPost))
