# Saturated integer arithmetic in [1..typemax]
⊕(a::T,b::T) where {T<:Unsigned}= a+b>=a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Unsigned}= a-b<=a ? a-b : one(T)
⊕(a::T,b::T) where {T<:Signed}= a+b>=a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Signed}= a-b>0 ? a-b : one(T)

# Side of hypercube with range φ
α(φ)= 2*round(Int,φ)+1
neighborhood(φ,Nsp)= ntuple(i->α(φ),Nsp)
mean_kernel(φ,Nsp)= ones(neighborhood(φ,Nsp)) ./ α(φ).^Nsp

# BitVector x SparseMatrixCSC{Bool}, used in overlap
import Base: *
*(z::BitVector,W::SparseMatrixCSC)= Vector(z)*W
*(z::Adjoint{Bool,BitVector},W::SparseMatrixCSC)= Vector(z.parent)'W
*(W::Adjoint{<:Any,<:SparseMatrixCSC},z::BitVector)= W*Vector(z)
*(W::SparseMatrixCSC,z::BitVector)= W*Vector(z)

# BitVector x Matrix{Bool}, used in overlap
*(z::BitVector,W::Matrix)= Vector(z)*W
*(z::Adjoint{Bool,BitVector},W::Matrix)= Vector(z.parent)'W
*(W::Adjoint{<:Any,<:Matrix},z::BitVector)= W*Vector(z)
*(W::Matrix,z::BitVector)= W*Vector(z)


#  Work around the narrow result types for SparseMatrixCSC{Bool} x Bool

# FIX SparseMatrixCSC{Bool} x Vector{Bool}
matmul_elt_op(a,b)= a*b+a*b
*(A::SparseMatrixCSC{TA,S}, x::StridedVector{Tx}) where {TA<:Bool,S,Tx} =
    (T = Base.promote_op(matmul_elt_op, TA,Tx); SparseArrays.mul!(similar(x, T, A.m), A, x, one(T), zero(T)))
*(adjA::Adjoint{<:Any,<:SparseMatrixCSC{TA,S}}, x::StridedVector{Tx}) where {TA<:Bool,S,Tx} =
    (A = adjA.parent; T = Base.promote_op(matmul_elt_op, TA,Tx); SparseArrays.mul!(similar(x, T, A.n), adjoint(A), x, one(T), zero(T)))