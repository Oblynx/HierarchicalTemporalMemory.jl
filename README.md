# Hierarchical Temporal Memory

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://oblynx.github.io/HierarchicalTemporalMemory.jl/dev)
[![Build Status](https://github.com/oblynx/HierarchicalTemporalMemory.jl/workflows/CI/badge.svg)](https://github.com/oblynx/HierarchicalTemporalMemory.jl/actions)
[![Coverage](https://codecov.io/gh/oblynx/HierarchicalTemporalMemory.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/oblynx/HierarchicalTemporalMemory.jl)


Julia implementation of core [Numenta HTM](https://numenta.com/) algorithms. Read the [docs](https://oblynx.github.io/HierarchicalTemporalMemory.jl/dev).

---

**Hierarchical Temporal Memory** is an abstract algorithmic **model of the human brain** (specifically the neocortex).
It's a tool for

- neuroscience: **understanding the human brain**
- machine learning: **predicting time series** and **detecting anomalies**

The main algorithms of this model, the Spatial Pooler and Temporal (Sequence) Memory, are described in:

- [Spatial Pooler](https://www.frontiersin.org/articles/10.3389/fncom.2017.00111/full)
- [Temporal Memory](https://www.mitpressjournals.org/doi/full/10.1162/NECO_a_00893) (section 3.3)

This package implements Numenta's Hierarchical Temporal Memory in simple and concise language,
relying on linear algebra and staying close to the
mathematical description in the source material.

## Experiments

Experiments and evaluation of this package lives in the [HTMexperiments repo](https://github.com/Oblynx/HTMexperiments).

## Roadmap

- [ ] Timeseries prediction tests, NAB results
- [ ] Explore temporal pooling ideas, influenced by forum discussions such as [this](https://discourse.numenta.org/t/exploring-the-repeating-inputs-problem/5498/14?u=oblynx).
- [ ] Maybe Backtracking TM? This non-biological spin on the TM algorithm hacks into [the problem of learning repeating inputs](https://discourse.numenta.org/t/my-analysis-on-why-temporal-memory-prediction-doesnt-work-on-sequential-data/3141).
The only reference is the [NUPIC implementation](https://github.com/numenta/nupic/blob/master/src/nupic/algorithms/backtracking_tm.py),
[focusing here](https://github.com/numenta/nupic/blob/1aea72abde4457878a16288d6786ffb088f69164/src/nupic/algorithms/backtracking_tm.py#L1666).
It isn't relevant to the current HTM research, only to applications.
