# Hierarchical Temporal Memory

<!---
[![Build Status](https://travis-ci.org/oblynx/htm.jl.svg?branch=master)](https://travis-ci.org/oblynx/htm.jl)

[![Coverage Status](https://coveralls.io/repos/oblynx/htm.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/oblynx/htm.jl?branch=master)

[![codecov.io](http://codecov.io/github/oblynx/htm.jl/coverage.svg?branch=master)](http://codecov.io/github/oblynx/htm.jl?branch=master)
--->

Julia implementation of core [Numenta HTM](https://numenta.com/) algorithms

This package implements Numenta's **Hierarchical Temporal Memory** in simple, expressive language,
relying on **linear algebra** as much as possible.
It strives to provide great performance as a 2nd consideration.

It is a _work in progress_.
Currently implemented algorithms:
- [Spatial Pooler](https://www.frontiersin.org/articles/10.3389/fncom.2017.00111/full)
- [Temporal Memory](https://www.mitpressjournals.org/doi/full/10.1162/NECO_a_00893) (section 3.3)


**Note**  both implementations are currently in the process of simplification. _Expect half the code to go._

## Design sources

The sources for this implementation are primarily the published papers for the [Spatial Pooler](https://www.frontiersin.org/articles/10.3389/fncom.2017.00111/full)
and the [Temporal Memory](https://www.mitpressjournals.org/doi/full/10.1162/NECO_a_00893).
For some details [BAMI](https://numenta.com/assets/pdf/biological-and-machine-intelligence/BAMI-Complete.pdf) provides extra info, but the pseudocode used there is pretty different from the definitions in this implementation.
For example, BAMI's Temporal Memory implementation processes each column separately in an imperative style,
while this implementation groups operations on data structures together as much as possible.

## Roadmap

- [ ] Timeseries prediction tests, NAB results
- [ ] Explore temporal pooling ideas, influenced by forum discussions such as [this](https://discourse.numenta.org/t/exploring-the-repeating-inputs-problem/5498/14?u=oblynx).
- [ ] Maybe Backtracking TM? This non-biological spin on the TM algorithm hacks into [the problem of learning repeating inputs](https://discourse.numenta.org/t/my-analysis-on-why-temporal-memory-prediction-doesnt-work-on-sequential-data/3141).
The only reference is the [NUPIC implementation](https://github.com/numenta/nupic/blob/master/src/nupic/algorithms/backtracking_tm.py),
[focusing here](https://github.com/numenta/nupic/blob/1aea72abde4457878a16288d6786ffb088f69164/src/nupic/algorithms/backtracking_tm.py#L1666).
It isn't relevant to the current HTM research, only to applications.
