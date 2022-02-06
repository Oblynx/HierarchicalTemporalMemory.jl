"""
    Network{T<:Integer}

Network of HTM [`Regions`](@ref) connected with feedforward (proximal) and/or contextual (distal) connections.
"""
struct Network{T<:Integer}
  regions::Vector{Region}
  "`region_α₋` is the cell activity of each region at the previous time step"
  region_α₋::Vector{<:HierarchicalTemporalMemory.CellActivity}
  """
  `circuit_proximal` is the proximal connection graph between regions.
  There are `length(regions) + 2` vertices, because at the end of the list an extra vertex is added for the input and the output.
  """
  circuit_proximal::SimpleDiGraph{T}
  circuit_distal::SimpleDiGraph{T}
end

"""
    Network(regions; connect_forward, connect_context)

Create a network of HTM [`Regions`](@ref).
The given regions are connected with feedforward (proximal) and/or contextual (distal) connections according to the given adjacency matrices.
One region serves as the input point and another one as the output, designated by their index on the `regions` vector.

## Inputs

- `regions::Vector{Regions}`: HTM [`Regions`](@ref) that will form the network
- `connect_forward: [N+2 × N+2]`: adjacency matrix for feedforward connections between regions and input/output nodes
- `connect_context: [N+2 × N+2]`: adjacency matrix for contextual connections between regions and input/output nodes

TODO: remove I/O from connect_* and move them to separate inputs:
TODO: MIMO, extend I/O to vectors of regions

- `in_forward`: index of the region that will receive external feedforward input
- `in_context`: index of the region that will receive external contextual input
- `out`: index of the region that will emit network output

## Adjacency matrix

The adjacency matrix has size [N+2 × N+2] because the 2 last nodes represent the input and the output connections.
Since the connections are directional, the adjacency matrix has an order: pre/post.

- The first N rows/columns refer to the connections between regions.
- Row N+1 is the input connection
- Column N+2 is the output connection

Example:

```
# vertices:
# 1 2 3 I O
c= [
  0 0 0 0 0  # 1
  1 0 0 0 0  # 2
  0 1 0 0 1  # 3
  1 0 0 0 0  # In
  0 0 0 0 0  # Out
]
# Connections:
c[2,1]  # 2 -> 1
c[3,2]  # 3 -> 2
c[4,1]  # in -> 1
c[3,5]  # 3 -> out
```
"""
Network(regions; connect_forward, connect_context=zeros(length(regions).*(1,1)))= begin
  circuit_proximal= SimpleDiGraph(length(regions)+2)
  circuit_distal= SimpleDiGraph(length(regions)+2)
  add_edges!(circuit_proximal, connect_forward)
  add_edges!(circuit_distal, connect_context)
  # Initialize the state of each region to `falses`
  Network(regions, map(r-> falses(length(r)), regions),
      circuit_proximal, circuit_distal)
end

"""
    networkPlot(network, plotFunction, extraArgs...)

Uses `plotFunction` to plot a network graph. Assumes that `plotFunction == GraphMakie.graphplot`, but might work with others.
`extraArgs` are passed as-is to the plotting function.
"""
networkPlot(network, plotFunction, extraArgs...)= begin
  allconnections= network.circuit_proximal ∪ network.circuit_distal
  # TODO: find the edges that come from the distal synapses!
  edgecolors= [
    e ∈ network.circuit_proximal|>edges ? :black : :cyan for e in allconnections|>edges
  ]
  plotFunction(allconnections,
      nlabels= [string.(1:length(network.regions));"in";"out"],
      node_color= [map(_->:black,1:length(network.regions)); :grey; :grey],  # Can't seem to get this to work
      node_marker= [map(_->:circle,1:length(network.regions)); :diamond; :diamond],  # Can't seem to get this to work
      edge_color= edgecolors, arrow_size= 12, node_size= 10,
      extraArgs...
  )
end

"`add_edges!(g,adjacency)` inserts the connections from an adjacency matrix into the graph"
add_edges!(g,adjacency)= map(findall(adjacency .> 0)) do edge
		add_edge!(g, edge.I...)
	end

# Evaluate a "vertex map", applying the Network's state to each region
(n::Network)(proximal, distal=falses(0))= begin
  # For each region, calculate its activation based on the previous activation of every neighbor
  n.region_α₋.= map(n.regions|> enumerate) do (i,r)
    proximal_input= getindexOverflow(n.region_α₋, proximal, Graphs.inneighbors(n.circuit_proximal,i))
    distal_input= getindexOverflow(n.region_α₋, distal, Graphs.inneighbors(n.circuit_distal,i))
    r(proximal_input,distal_input).active
  end
  # Emit output activation
  getindexOverflow(n.region_α₋, proximal, Graphs.inneighbors(n.circuit_proximal,length(n.regions)+2))|> gateCombine
end

getindexOverflow(a,overflow,i)= getindexOverflow.(Ref(a),Ref(overflow),i)
getindexOverflow(a,overflow,i::Integer)= i .<= length(a) ? a[i] : overflow