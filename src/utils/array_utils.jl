"""
    vcat!!(s::SparseMatrixCSC, J,V)

*WARNING*: `s` is invalid after this operation!!! Its symbol should be reassigned
to the output of `vcat!!`.
Append new rows to `s` with 1 value `V[r]` at column `J[r]` each.
Because `SparseMatrixCSC` is immutable, return a new, valid
`SparseMatrixCSC` that points to the original's data structures.
For large matrices, this is much faster than `vcat`.
"""
function vcat!!(s::SparseMatrixCSC, J,V)
  length(V)==length(J) || error("[vcat!!] J,V must have the same length")
  k= length(V); k_s= nnz(s)
  m= s.m+k
  resize!(s.nzval, k_s+k)
  resize!(s.rowval, k_s+k)

  # Rearrange values-to-add by ascending column
  col_order= sortperm(J)
  J= J[col_order]; V= V[col_order]
  # Calculate how many steps forward each column start moves
  colptr_cat= copy(s.colptr)
  for c in J
     @inbounds colptr_cat[c+1:end].+= 1
  end

  ## Fill in the new values at the correct places
  # NOTE start from the end, because that's where the empty places are
  for c= s.n:-1:1
    colrange= s.colptr[c] : s.colptr[c+1]-1
    colrange_cat= colptr_cat[c] : colptr_cat[c+1]-1
    # 1: Transport previous values to new places`
    @inbounds s.rowval[colrange_cat[1:length(colrange)]].= s.rowval[colrange]
    @inbounds s.nzval[colrange_cat[1:length(colrange)]].= s.nzval[colrange]

    # 2: add new values
    if length(colrange_cat) > length(colrange)
      # OPTIMIZE J.==c is a lot of comparisons!
       @inbounds s.rowval[colrange_cat[length(colrange)+1:end]].=
          col_order[J .== c] .+ s.m
       @inbounds s.nzval[colrange_cat[length(colrange)+1:end]].= V[J .== c]
    end
  end

  # Construct the new SparseMatrixCSC
  SparseMatrixCSC(m,s.n,colptr_cat,s.rowval,s.nzval)
end
"""
    hcat!!(s::SparseMatrixCSC, I,V)

*WARNING*: `s` is invalid after this operation!!! Its symbol should be reassigned
to the output of `hcat!!`.
Append new columns to `s` with 1 value `V[c]` at row `I[c]` each.
Because `SparseMatrixCSC` is immutable, return a new, valid
`SparseMatrixCSC` that points to the original's data structures.
For large matrices, this is *much* faster than `hcat`.
"""
function hcat!!(s::SparseMatrixCSC, I,V)
  length(V)==length(I) || error("[hcat!!] I,V must have the same length")
  k= length(V); k_s= nnz(s)
  n= s.n+k
  resize!(s.nzval, k_s+k)
  resize!(s.rowval, k_s+k)
  resize!(s.colptr, n+1)
  s.nzval[k_s+1:end].= V
  s.rowval[k_s+1:end].= I
  s.colptr[s.n+2:end].= s.colptr[s.n+1] .+ (1:k)
  # Construct the new SparseMatrixCSC
  SparseMatrixCSC(s.m,n,s.colptr,s.rowval,s.nzval)
end
# Change just the number of columns, without adding any new values
function hcat!!(s::SparseMatrixCSC,k)
  n= s.n+k
  resize!(s.colptr,n+1)
  s.colptr[s.n+2:end].= s.colptr[s.n+1]
  SparseMatrixCSC(s.m,n,s.colptr,s.rowval,s.nzval)
end
