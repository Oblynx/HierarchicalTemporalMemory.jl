# Saturated integer arithmetic
⊕(a::T,b::T) where {T<:Unsigned}= a+b>a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Unsigned}= a-b<a ? a-b : T(0)
⊕(a::T,b::T) where {T<:Signed}= a+b>a ? a+b : typemax(T)
⊖(a::T,b::T) where {T<:Signed}= a-b>0 ? a-b : T(0)
