"""
    Region(SPParams, TMParams; recurrent= true)
A Region is a set of neurons arranged in minicolumns with 2 input gates:
- _proximal_ (size: number of minicolumns Nc): feedforward input that activates some of the region's minicolumns
- _distal_ (size: number of neurons Nn): contextual input that causes individual neurons to become predictive and fire preferentially on the next time step

Each gate accepts 1 or more input SDRs of the correct size, which will be ORed together.
If `recurrent= true`, the distal gate implicitly receives the same layer's state from the last time step as input (in addition to any SDR given explicitly).

The activation of minicolumns resulting from the proximal synapses is defined by the [`SpatialPooler`](@ref) algorithm,
while the activation of individual neurons is defined by the [`TemporalMemory`](@ref).

# Example

```julia
r= Region(SPParams(), TMParams(), recurrent= true)
feedforward_input= bitrand(Nc(r))

# activate based on feedforward input and the region's previous activation
active, predictive= r(feedforward_input)
# learn (adapt synapses)
step!(r, feedforward_input)

# use explicit contextual input eg from another region, that will be ORed to the region's state
distal_input= sprand(Bool,Nn(r), 0.003)|> BitVector
active, predictive= r(feedforward_input, distal_input)
```
"""