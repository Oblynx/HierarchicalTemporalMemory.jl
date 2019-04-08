module SpatialPoolerM

include("common.jl")
include("topology.jl")

# NOTE: Instead of making type aliases, perhaps parametrize IntSP etc?
struct SPParams{Nin,Nsp}
  inputSize::NTuple{Nin,UIntSP}
  spSize::NTuple{Nsp,UIntSP}
  input_potentialRadius::UIntSP
  sparsity::FloatSP
  θ_potential_prob_prox::FloatSP
  θ_permanence_prox::FloatSP
  θ_stimulus_act::UIntSP
  n_active_perinhibit::UIntSP
  enable_local_inhibit::Bool
  enable_learning::Bool
  topologyWraps::Bool
end

# SPParams convenience constructor and default arguments.
#   Obligatory validity checks should be an inner constructor
function SPParams(inputSize::NTuple{Nin,UIntSP}= UIntSP.((32,32)),
                  spSize::NTuple{Nsp,UIntSP}= UIntSP.((64,64));
                  input_potentialRadius=16,
                  sparsity=0.2,
                  θ_potential_prob_prox=0.5,
                  θ_permanence_prox=0.4,
                  θ_stimulus_act=0,
                  n_active_perinhibit=10,
                  enable_local_inhibit=true,
                  enable_learning=true,
                  topologyWraps=false
                 ) where {Nin,Nsp}
  # Param transformation
  # cover the entire input space, reasonable if no topology
  if input_potentialRadius == 0
    input_potentialRadius= max(inputSize)
  end

  ## Construction
  SPParams{Nin,Nsp}(inputSize,spSize,input_potentialRadius,sparsity,
           θ_potential_prob_prox,θ_permanence_prox,θ_stimulus_act,
           n_active_perinhibit,
           enable_local_inhibit,enable_learning,topologyWraps)
end

struct SpatialPooler{Nin,Nsp} #<: Region
  params::SPParams
  proximalSynapses::AbstractSynapses

  # Construct and initialize
  # Nin, Nsp: number of input and spatial pooler dimensions
  function SpatialPooler(params::SPParams{Nin,Nsp}= SPParams()) where {Nin,Nsp}
    """ NOTE:
      params: includes size (num of cols)
      Initialize potential synapses. For every column:
      - find its center in the input space
      - for every input in hypercube, draw rand Z
        - If < 1-θ_potential_prob_prox
         - Init perm: rescale Z from [0..1-θ] -> [0..1]: Z/(1-θ)
    """

    proximalSynapses= initProximalSynapses(params.inputSize,params.spSize,
        params.input_potentialRadius,params.θ_potential_prob_prox,
        params.θ_permanence_prox)
    new{Nin,Nsp}(params,proximalSynapses)
  end
end

# Make an input x spcols synapse permanence matrix
const permT= SynapsePermanenceQuantization
function initProximalSynapses(inputSize,spSize,input_potentialRadius,
      θ_potential_prob_prox,θ_permanence_prox)
  spColumns()= CartesianIndices(spSize)
  # Map column coordinates to their center in the input space. Column coords FROM 1 !!!
  xᶜ(yᵢ)= floor.(UIntSP, (yᵢ.-1) .* (inputSize./spSize)) .+1
  xᵢ(xᶜ)= [x.I for x in hypercube(UIntSP.(xᶜ),input_potentialRadius, inputSize)]

  # Draw permanences from uniform distribution. Connections aren't very sparse (40%),
  #   so prefer a dense matrix
  #permanence_sparse(xᵢ)= sprand(permT,length(xᵢ),1, 1-θ_potential_prob_prox)
  permanence_dense(xᵢ)= begin
    p= rand(permT,size(xᵢ))
    effective_θ= floor(permT, (1-θ_potential_prob_prox)*typemax(permT))
    p[p .> effective_θ].= 0
    p[p .< effective_θ].= rand(permT, count(p.<effective_θ))
    return p
  end

  proximalSynapses= DenseSynapses(inputSize,spSize)
  for yᵢ in spColumns()
    yᵢ= yᵢ.I
    xi= xᵢ(xᶜ(yᵢ))
    proximalSynapses[xi, yᵢ]= permanence_dense(xi);
  end
  return proximalSynapses
end


"""
      step!(z::CellActivity,proximalSynapses::Synapses; params::SPParams)

  Evolve the Spatial Pooler to the next timestep.

  ...
  # Input
    - `z`: array of active input cells, arranged in a metric space.
    - `params`: structure of miscellaneous SP hyperparameters
      - `input_potentialRadius`
      - `sparsity`
      - `θ_potential_prob_prox`
      - `θ_permanence_prox`
      - `θ_stim_act`
      - `enable_local_inhibit`
      - `enable_learning`
  ## Modified
    - proximalSynapses: as a result of the learning process, the proximalSynapses are
        modified at each step. Maps from input array to array of minicolumns.
        proximalSynapses[x_i,y_i]:= permanence value, where x_i,y_i are tuples
  # Output
    - minicolAct: array of minicolumn activation. Minicolumns are embedded in a metric space,
        and the array dimensionality represents the spatial dimensions (normally 2 - affects
        local inhibition)
  ...

  # Notes

  ## Definitions
    - `xᵢ`: position of input cell `i`
    - `yᵢ`: position of minicolumn `i`
    - `γ`: side of hypercube of potential connections in input space
    - `φ`: radius of local inhibition sphere in minicolumn space

  ## Mapping input to minicolumns

  There is an implied spatial mapping between the input and output spaces. Minicolumn `i` has
  potential synapses only with some input cells close to input `i` ("close": hypercube around
  cell `i`) (param: `input_potentialRadius`).
  For every input in that area, there is a uniformly-distributed probability that
  it connects to the minicolumn (param: `θ_potential_prob_prox`).
  Permanence values for potential synapses are also uniformly iid, with connection threshold
  0.5 (param: `θ_permanence_prox`). Performance NOT SENSITIVE to this.

  ## Local inhibition

  Local inhibition happens in the neighborhood of minicolumn `i`: euclidean hypersphere
  around `y_i` of radius `φ`. The radius is dynamically adjusted. Its initial value is
  determined by the ratio `R` of the size of the output to input space -- it is assumed that
  the mapping between the input and output space is an isotropic scaling; eg, the spaces are
  rectangular with the same aspect ratio.

      ``φ_0 = Rγ``

  Of course this can be generalized to the case of a non-isotropic scaling between the 2
  spaces, by letting `R` be the transformation matrix. If the dimensions of the 2 spaces
  are not the same, however, there will be extra degrees of freedom.

  Local inhibition makes sense only if the input space has topology, and can be turned off
  (param: `enable_local_inhibit`).

  ## SP activation

  The final activation of each minicolumn is a result of its (boosted) "overlap" `o` with the
  input. There is a threshold (param: `θ_stimulus_act`), which the overlap must pass. Then, local
  inhibition allows only the top `s`% of the neighborhood to become active
  (param: `sparsity` ≈ 2%).

  ## Learning

  (param: `enable_learning`)

"""
#function step!(z::CellActivity,proximalSynapses::Synapses; params::SPParams)
function step!(z::CellActivity, sp::SpatialPooler)

end

end
