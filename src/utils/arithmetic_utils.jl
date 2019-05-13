# Saturated integer arithmetic in [1..typemax]
⊕(a::T,b::T) where {T<:Unsigned}= a+b>a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Unsigned}= a-b<a ? a-b : one(T)
⊕(a::T,b::T) where {T<:Signed}= a+b>a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Signed}= a-b>0 ? a-b : one(T)

# Side of hypercube with range φ
α(φ)= 2*round(Int,φ)+1

# Vector x SparseMatrixCSC{Bool}, used in overlap
import Base: *
*(z::Adjoint{<:Any,<:AbstractArray{<:Any,1}},W::SparseMatrixCSC{Bool})=
    map(c-> sum(@views z.parent[rowvals(W)[nzrange(W,c)]]), 1:size(W,2))'
#*(z::AbstractArray{<:Any,1},W::SparseMatrixCSC{Bool})=
*(W::Adjoint{Bool,<:SparseMatrixCSC{Bool}},z::AbstractArray{<:Any,1})=
    map(c-> sum(@views z[rowvals(W.parent)[nzrange(W.parent,c)]]), 1:size(W,1))
#*(W::SparseMatrixCSC{Bool},z::AbstractArray{<:Any,1})=
