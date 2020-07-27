```@meta
CurrentModule = HierarchicalTemporalMemory
```

# Hierarchical Temporal Memory

Hierarchical Temporal Memory is an abstract algorithmic **model of the human brain** (specifically the neocortex).
It's a tool for

- neuroscience: **understanding the human brain**
- machine learning: **predicting time series** and **detecting anomalies**

The main algorithms of this model, the Spatial Pooler and Temporal (Sequence) Memory, are described in:

- [The HTM Spatial Pooler—A Neocortical Algorithm for Online Sparse Distributed Coding](https://www.frontiersin.org/articles/10.3389/fncom.2017.00111/full)
- [Continuous Online Sequence Learning with an Unsupervised Neural Network Model](https://www.mitpressjournals.org/doi/10.1162/NECO_a_00893) (section 3.3)

The official implementation of this model in Python ([NUPIC](https://github.com/numenta/nupic)) serves as a reference point and as source of truth
for many implementation details, but it doesn't take advantage of the data-driven design that the
source material encourages and ends up quite verbose.
This implementation uses Julia's expressivity to remain faithful to the papers' terminology,
attempting to express the algorithms more simply and concisely, and thus instigate further research on them.
Some essential features of this expressivity are broadcasting, duck-typed interfaces and unicode source code.

### What is the HTM?

The Hierarchical Temporal Memory (HTM) is a biologically constrained theory,
aiming primarily to model the function of the neocortex (a structure of the human brain),
and as a secondary goal, machine learning applications.
The algorithms expose many fundamental properties which are used to test this implementation.

In contrast to many established neural network models, the HTM neuron performs coincidence detection across multiple input "dendrites".
HTM is actually closer to a spiking neural network, with binary synapses and signals, that encodes information in population codes.
Spatial pooling and the temporal memory are both unsupervised processes that adapt continuously; together, they learn to identify sequences in noisy input time series.

HTM theory is not yet complete, lacking a definitive way to stabilize sequence representations and compose small models. Exactly for this reason, we believe that a concise and high level model can accelerate the research.


## Roadmap

- Timeseries prediction tests, NAB results
- Sensorimotor inference and temporal pooling ideas, influenced by forum discussions such as [this](https://discourse.numenta.org/t/exploring-the-repeating-inputs-problem/5498/14). This goes in the direction of the biggest current problems:
  - temporal noise
  - hierarchical model composition

## Acknowledgements

- Maria Litsa: logo
