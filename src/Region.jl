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
struct Region
  sp::SpatialPooler
  tm::TemporalMemory
end
Region(spp::SPParams,tmp::TMParams; recurrent=true, distal_input_size=0)= begin
  @assert prod(spp.szₛₚ) == tmp.Nc "Number of minicolumns in Spatial Pooler and Temporal Memory in the same region must match"
  Region(SpatialPooler(spp), TemporalMemory(tmp, recurrent=recurrent, distal_input_size=distal_input_size))
end
Nc(r::Region)= r.tm.params.Nc
Nₙ(r::Region)= Nₙ(r.tm)
Base.size(r::Region)= (r.sp.params.szₛₚ..., r.tm.params.k)
Base.length(r::Region)= Nₙ(r)


"`distalSynapses(r::Region)` is the adjacency matrix of the Region's connected distal synapses in {pre- × post-}synaptic neuron format."
distalSynapses(r::Region)= Wd(r.tm)
"`proximalSynapses(r::Region)` is the adjacency matrix of the Region's connected proximal synapses in {pre- × post-}synaptic neuron format."
proximalSynapses(r::Region)= Wₚ(r.sp)

"""
    (r::Region)(proximal, distal=falses(0))

Stimulates the region with the given inputs, without adapting it (pure function).
If distal input isn't given explicitly, recurrent connections are still used (if present).

See also [`Region`](@ref)
"""
(r::Region)(proximal, distal=falses(0))= @chain gateCombine(proximal) begin
  r.sp
  r.tm(_, gateCombine(distal))
end

# Support easier chaining of regions
RegionOutput= NamedTuple{(:active, :predictive, :bursting)}
(r::Region)(proximal::RegionOutput, distal=falses(0))= r(proximal.active, distal)

"""
    step!(r::Region, proximal, distal=falses(0))

Stimulates the region with the given inputs, adapting it following the learning rules.
If distal input isn't given explicitly, recurrent connections are still used (if present).

See also [`Region`](@ref)
"""
step!(r::Region, proximal, distal=falses(0))= @chain gateCombine(proximal) begin
  step!(r.sp, _)
  step!(r.tm, _, gateCombine(distal))
end

"`reset!(r::Region)` unlearns the region's synapses (and other internal state), restoring it to the state at construction"
reset!(r::Region)= begin
  reset!(r.sp)
  reset!(r.tm)
end

"""
    connectContext!(output::Region, input::Region)

Connect contextually 2 regions `output -> input` by wiring the activation of
`output` to the context gate of `input`. Only `input` changes.
"""
#connectContext!(input::Region, output::Region)

gateCombine(x::Vector{T} where T <: CellActivity)= length(x) > 0 ? reduce(.|, x) : falses(0)
gateCombine(x)= x
