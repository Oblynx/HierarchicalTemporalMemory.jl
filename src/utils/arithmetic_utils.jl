# Saturated integer arithmetic in [1..typemax]
⊕(a::T,b::T) where {T<:Unsigned}= a+b>a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Unsigned}= a-b<a ? a-b : one(T)
⊕(a::T,b::T) where {T<:Signed}= a+b>a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Signed}= a-b>0 ? a-b : one(T)

# Side of hypercube with range φ
α(φ)= 2*round(Int,φ)+1

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
# FIX SparseMatrixCSC{Bool} x SparseVector{Bool}
function *(A::SparseMatrixCSC, x::AbstractSparseVector)
    @assert !Base.has_offset_axes(A, x)
    y = LOCAL_densemv(A, x)
    initcap = min(nnz(A), size(A,1))
    SparseArrays._dense2sparsevec(y, initcap)
end
*(adjA::Adjoint{<:Bool,<:SparseMatrixCSC{Bool}}, x::AbstractSparseVector) =
    (A = adjA.parent; LOCAL_At_or_Ac_mul_B(SparseArrays.dot, A, x))


function LOCAL_densemv(A::SparseMatrixCSC, x::AbstractSparseVector; trans::AbstractChar='N')
    local xlen::Int, ylen::Int
    @assert !Base.has_offset_axes(A, x)
    m, n = size(A)
    if trans == 'N' || trans == 'n'
        xlen = n; ylen = m
    elseif trans == 'T' || trans == 't' || trans == 'C' || trans == 'c'
        xlen = m; ylen = n
    else
        throw(ArgumentError("Invalid trans character $trans"))
    end
    xlen == length(x) || throw(DimensionMismatch())
    T = Base.promote_op((a,b)->a*b+a*b, eltype(A), eltype(x))
    y = Vector{T}(undef, ylen)
    if trans == 'N' || trans == 'N'
        SparseArrays.mul!(y, A, x)
    elseif trans == 'T' || trans == 't'
        SparseArrays.mul!(y, transpose(A), x)
    elseif trans == 'C' || trans == 'c'
        SparseArrays.mul!(y, adjoint(A), x)
    else
        throw(ArgumentError("Invalid trans character $trans"))
    end
    y
end
function LOCAL_At_or_Ac_mul_B(tfun::Function, A::SparseMatrixCSC{TvA,TiA}, x::AbstractSparseVector{TvX,TiX}) where {TvA,TiA,TvX,TiX}
    @assert !Base.has_offset_axes(A, x)
    m, n = size(A)
    length(x) == m || throw(DimensionMismatch())
    Tv= Base.promote_op((a,b)->a*b+a*b, TvA,TvX)
    Ti = promote_type(TiA, TiX)

    xnzind = SparseArrays.nonzeroinds(x)
    xnzval = nonzeros(x)
    Acolptr = A.colptr
    Arowval = A.rowval
    Anzval = A.nzval
    mx = length(xnzind)

    ynzind = Vector{Ti}(undef, n)
    ynzval = Vector{Tv}(undef, n)

    jr = 0
    for j = 1:n
        s = SparseArrays._spdot(tfun, Acolptr[j], Acolptr[j+1]-1, Arowval, Anzval,
                   1, mx, xnzind, xnzval)
        if s != zero(s)
            jr += 1
            ynzind[jr] = j
            ynzval[jr] = s
        end
    end
    if jr < n
        resize!(ynzind, jr)
        resize!(ynzval, jr)
    end
    SparseVector(n, ynzind, ynzval)
end
