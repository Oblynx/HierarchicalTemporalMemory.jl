"""
    growseg!(synapses, Nseggrow)

Linearly append new segments to the postsynaptic dimensions. If `length(postDims)>1`, append
to the last dimension. This doesn't create any new synapses, it only affects the matrix size
(assume the synapses are between presynaptic cell bodies and postsynaptic dendritic segments,
like the DistalSynapses of the TM)
"""
function growseg!(s::SparseSynapses, Nseggrow)
  s.data= hcat!!(s.data, Nseggrow)
end
