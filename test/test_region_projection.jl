### A Pluto.jl notebook ###
# v0.17.5

using Markdown

# ╔═╡ 0d3bf5f6-1171-11ec-0fee-c73bb459dc3d
begin
	using HierarchicalTemporalMemory
	using Random, Chain, Setfield, Statistics, Test
end

# ╔═╡ 1bb0fcfc-2d7a-4634-9c93-263050c56a55
md"""
# Test Region API

This notebook tests the Region API, using it to define projections of neuronal activity between regions.

# Projection

This notebook implements the simplest operation of assembly calculus, *projection*, with HTM.

Assembly calculus and HTM share the concept of "Region" as a modular circuit of neurons.
HTM imposes specific structure in the Region.
The question is: _is the HTM structure behaving according to assembly calculus_?

Projection of assembly `x` from region A -> B is the operation where a stable assembly `y` is generated in B that fires consistently when `x` fires in A.
In assembly calculus this is shown to happen simply by repeated firing of `x` for a number of time steps:

```algo
repeat T:    # T: constant ~10
  fire x
```

Alternatively (to not require a constant T):

```algo
repeat until yₜ converges:
  fire x
```

Note that we don't necessarily expect point stability, but a limit circle of low enough radius. More on this with the convergence measure.

## Experiment

### The Plan

We will implement this simple algorithm with HTM regions and check the convergence of `y`.
If `yₜ` converges to a limit circle as $t→∞$ (practically 10-100 steps) of a small enough radius, we will consider the projection implemented.

But how small is small enough?
The algorithm parameters might have a big impact on the convergence radius, or might even prohibit convergence.
Intuitively in order to set an expectation, let the limit radius $|yₜ₁ - yₜ₂| < 5\%|y|$.

Let's define the relative distance behind this limit radius.
Since $yᵢ$ are sparse binary vectors:
- the core "similarity" kernel will be bitwise AND: $yᵢ .\& yⱼ$
- the norm $|yᵢ|$ will be the count of `true`

The relative distance $\frac{|yᵢ - yⱼ|}{|y|}$ can be:
"""

# ╔═╡ 70471bdc-660e-442e-b92a-f486abd120a7
reldistance(yᵢ,yⱼ)= 1 - count(yᵢ .& yⱼ) / min(count(yᵢ), count(yⱼ))

# ╔═╡ 7620c202-c6cf-44db-9cda-13642e28b45a
md"""
which is bounded by $0 ≤ \texttt{reldistance}(yᵢ, yⱼ) ≤ 1$
"""

# ╔═╡ 043f8da8-f17a-4486-9c49-7d5ecc75457f
md"""
### Collect the ingredients

Let's define the HTM regions A, B with the same properties (adapting the input size to match).
Minicolumns will be explained later.
"""

# ╔═╡ bbaf0a64-2471-4106-a27c-9dd5a4f58c7c
begin
	Nin= 1e3|> Int   # input size
	Nn= 4e5          # number of neurons in each area
	k= 10            # neurons per minicolumn
	_Nc()= floor(Int,Nn/k) # number of minicolumns
	sparsity()= 1/sqrt(_Nc());
end

# ╔═╡ d4683829-b214-4d79-890d-bcc902bcef2b
params_A= (
	sp= SPParams(szᵢₙ=Nin, szₛₚ=_Nc(), s= sparsity(), prob_synapse=1e-3, enable_local_inhibit=false),
	tm= TMParams(Nc=_Nc(), k=k, p⁺_01= .11, θ_stimulus_learn=15, θ_stimulus_activate= 22)
)

# ╔═╡ 5b0c7174-dc2b-4b28-8cda-fc2e8a37151c
params_B= @set params_A.sp.szᵢₙ= params_A.tm.Nₙ

# ╔═╡ 334b271d-247c-465c-ae82-f91007a6d9d0
md"The regions:"

# ╔═╡ 4833f12f-3eac-407c-a9ce-0d1aea216077
A= Region(params_A.sp, params_A.tm);

# ╔═╡ 45d8e50b-8baa-4da2-8cd0-5c81d634c450
B= Region(params_B.sp, params_B.tm);

# ╔═╡ 91fa8319-1702-4cad-8ae8-0c1ed51a7bb8
md"""
This is the assembly `x`, which first needs a random input.
"""

# ╔═╡ 3ee589ed-0fe0-4328-88e8-d2fb6a98bf28
x= @chain bitrand(Nin) A(_).active;

# ╔═╡ 6790a86a-3990-4c6a-878f-c18779f8d48d
md"""
### The Projection operation

Now all we need to do is to repeatedly stimulate `B` with `x` and let it learn.
Each time `B` is stimulated, it will produce a `yᵢ`:
"""

# ╔═╡ 5458c6ae-ace2-4928-8a9b-ef919a1e97cb
y₁= B(x).active;

# ╔═╡ 6b56422c-5f9b-41d8-a080-ef5ca3d7db7b
md"""
But in order to let region `B` learn from `x`, we need to call the `step!` function, which will return the same output as `yᵢ` the first time it's called, while at the same time adapting synapses:
"""

# ╔═╡ 3229da2a-92f3-4064-bb80-cbd9f5523d7d
begin
	reset!(B)
	md"`step!(B,x).active == y₁`: $((step!(B,x).active .== y₁) |> all)"
end

# ╔═╡ 71f21302-04db-41aa-a259-f3be2b7bc271
md"We will now explore the result of repeated stimulation"

# ╔═╡ 5e0ac810-1689-4bfb-88a8-85504cd821b6
md"""
### Repeated stimulation

To plot the convergence of $yᵢ$ we will now produce them repeatedly and store them.
Each experiment will run for `T` steps and we will run many experiments with different `x` each.
"""

# ╔═╡ 1015f629-9818-4dbb-b574-97c552e96164
T= 30; experiments=10;

# ╔═╡ 62d41be1-2970-48e1-b689-c2ecf1ab10ce
md"""
The results will be:

- `y[T,experiments]` is the entire history of `yᵢ`
- `yState[experiments]` is the end state of the region B for each experiment
"""

# ╔═╡ d08cce9d-dd9c-4530-82ae-bf1db8be3281
# Send SDRs from A -> B
begin
	randomX()= @chain bitrand(Nin) A(_).active;
	stepRepeatedly(B,x)= [step!(B,x).active for t= 1:T], B
	experiment(id)= stepRepeatedly(
		deepcopy(B),
		randomX()
	)
	reshapeMatrix(x,d1,d2)= @chain x begin
	  Iterators.flatten
      collect
      reshape(_, d1,d2)
	end
	splitReshapeExp(experimentVec)= (
		( @chain experimentVec first.(_) reshapeMatrix(_,T, experiments) ),
		( @chain experimentVec Base.rest.(_,2) first.(_) ),
	)
	reset!(B)
	y, yState= @chain begin
	  @sync [Threads.@spawn experiment(e) for e= 1:experiments]
	  fetch.(_)
	  splitReshapeExp
	end
	nothing
end

# ╔═╡ 6a20715a-9dc9-461a-b6a2-f02522e277f0
md"We calculate the $Δyₜ=\texttt{reldistance}(yₜ,yₜ₊₁) ∀ t∈\{1..T-1\}$ and the experiment median. This metric will show whether `yₜ` converges."

# ╔═╡ e63a5860-587c-4aff-91be-a894b3443943
Δyₜₑ()= [reldistance(y[i,e], y[i+1,e]) for i=1:T-1, e=1:experiments];

# ╔═╡ c866c71e-5dce-4af1-84bb-045815d1acb9
expmedian(y)= median(y, dims=2);

# ╔═╡ 75560584-1631-4c93-8808-e269d345e1c8
Δȳₜ= Δyₜₑ()|> expmedian;

# ╔═╡ 456021aa-3dbf-4102-932f-43109905f9eb
begin
  # TEST: Comment out plotting
	#plot(Δyₜₑ(), minorgrid=true, ylim= [0,.3], opacity=0.3, labels=nothing,
	#	title="Convergence of yₜ", ylabel="Relative distance per step Δyₜ",
	#	xlabel="t")
	#plot!(Δȳₜ, linewidth=2, label="median Δȳ")
	#hline!(zeros(T) .+ .05, linecolor=:black, linestyle=:dash, label="5% limit")
	@test all(Δȳₜ[25:end] .< .05)
end

# ╔═╡ 56e0da0b-8858-459a-9aae-0eba4797cc06
md"""
## Understanding the convergence plot

As we see from the median (thick line), the experiments **converge after step $t=20$**.
This is double what assembly theory expects (10 steps), but it might be sensitive to the model's parameters.

So far, it looks like the "projection" operation has been implemented with HTM successfully.

#### Why is the distance exactly 0 in the beginning?

_Distal and proximal synapses_

This has to do with the biggest deviation of HTM from assembly calculus.
In assembly calculus, all synapses can trigger neurons to fire.
In HTM there are 2 kinds of synapses: _proximal_ and _distal_.
Only the proximal ones cause neurons to fire; distal synapses only cause neurons to win in competition among many that are proximally excited (keyword: *context*).

Neurons are grouped in "minicolumns", wherein they share the same proximal synapses, differing only in distal synapses.
Feedforward connectivity from A → B is through proximal synapses, while recurrent connectivity within B is through distal.
Every time `x` fires the same large set of neurons (minicolumns) is primed to fire in B.
In the beginning, before recurrent connections form through learning, every neuron in the primed minicolumns fires.
Gradually, recurrent connections form, which cause only a few neurons (often 1) in each minicolumn to be "excited" through distal connections.
But this distal excitement doesn't cause neurons to fire;
only, if the minicolumn happens to be activated in the following step, the distally excited neuron will win an in-column competition and be the only one to fire.

If this hypothesis is correct, then we expect to see a significant drop in the number of active neurons in B after the first few steps. Let's test this.
"""

# ╔═╡ cf83549c-03b1-4f7d-be29-d3a29da3e8f7
activity_n(y)= count.(y)|> expmedian

# ╔═╡ 85dfe3ed-cf70-4fde-a94a-f70c3fe4abf6
begin
	#using Plots.PlotMeasures
	#plot(activity_n(y)/activity_n(y)[1], linecolor=:blue, foreground_color_subplot=:blue, xlabel="t", ylabel="Relative activity in B", rightmargin=14mm, legend=:none)
	#plot!(twinx(), Δȳₜ, linecolor=:red, foreground_color_subplot=:red, ylabel="median Δȳ", legend=:none)
end

# ╔═╡ 2b6d959f-63bb-4d42-a34d-70d93f6a1636
md"""
The difference in activity is much less than `k` (neurons per minicolumn), but it is still evident.
This means that after convergence there are still many neurons firing in each minicolumn;
in fact, the average number of neurons firing in each active minicolumn should be close to the region's activity in the previous plot.
"""

# ╔═╡ 3a5e3aa0-e34e-457c-a405-9bc95cd88910
activity_per_active_minicolumn(y)= @chain y reshape(_,k,:) count(_, dims=1) filter(x->x>0, _) mean

# ╔═╡ 5ec611f4-d3ea-4c5d-9221-4dcf2da3e18c
@test sum(abs.(expmedian(activity_per_active_minicolumn.(y)) .- activity_n(y)/activity_n(y)[1]*k)) < 1e-10

# ╔═╡ 3df40867-674b-405a-a05c-0733a4caaa67
md"The 2 are almost identical, therefore this explanation of the first few steps in the graph seems to hold up."

# ╔═╡ c3896446-3a24-413a-afab-6a67b07092f5
md"""
## Assemblies have dense interconnections

Assemblies are expected to have denser interconnections than random collections of neurons. To measure this property, we define the interconnection measure to be the number of synapses with pre- and post-synaptic neurons in the same population:
"""

# ╔═╡ 86e68710-1323-434e-b24b-d86b2719f53a

# ╔═╡ da7a8cfb-986c-4598-8696-30c36ffb263d

# ╔═╡ dcbe4617-7314-42c1-87bf-57ca82554a20
interconnectionMeasure(activation, region)= activation' * distalSynapses(region) * activation

# ╔═╡ 059f3e13-56f6-4dc6-9570-19c74996d1ef
md"""
Using the interconnection measure we can now determine the average interconnectivity of the assemblies across experiments and compare with the average interconnectivity of 30 random neuronal activations that aren't assemblies.
"""

# ╔═╡ 8e9003fa-c822-4508-9862-58a816d9242d
assemblyInterconnection= map(interconnectionMeasure, y[end,:], yState)|> mean

# ╔═╡ d4cfbfe7-ba6f-4936-8854-8d49277657d2
randomInterconection= map(yState) do (r)
	@chain begin
		[bitrand(Nₙ(r)) for i= 1:30]       # 30 random activations
		interconnectionMeasure.(_,Ref(r))  # interconnection measure for each
		mean                               # mean interconnection among the 30
	end
end |> mean                                # mean across the experiments

# ╔═╡ dfff3823-d750-40e1-9ddf-769cb2c7e575
md"The average interconnectivity of assemblies is **×$(round(assemblyInterconnection / randomInterconection, digits=1))** times higher than random. It probably increases as the training process continues. Let's confirm this with a training graph:"

# ╔═╡ ed61ded0-d665-46a9-bed8-cd83cb0a545a
begin
	train_interconnection!(R,x)= begin
	    y= step!(R,x).active
		interconnectionMeasure(y,R)
	end
	reset!(B)
	trainingcurve= [train_interconnection!(B,x) for t= 1:1.5T]
	md"This cell produces the training curve."
end

# ╔═╡ 5bd5049c-de0d-4838-9c82-9cef604e650e
begin
  # TEST: comment out plots
	#plot(trainingcurve,
	#	minorgrid=true, title="Assembly interconnection training curve",
	#	ylabel="assembly interconnection",
	#	xlabel="t", label=:none
	#)
	#vline!([30,30],linecolor=:black, opacity=0.3, linestyle=:dash, label=:none)
  @test trainingcurve[end] > trainingcurve[5] && trainingcurve[end] > 5000
end

# ╔═╡ b886095d-d449-4334-99cf-44b800bb4fc4
md"In the graph we can see that the interconnection measure reaches the limit cycle at the same cutoff $T=30$ that we chose to consider assemblies stable"

# ╔═╡ 8fdacada-55df-4abd-9501-7405e608529b
md"""
#### Is `x` an assembly?
### Note on defining assemblies and on input regions

In this notebook, we activate region `A` arbitrarily, through an external mechanism.
Is the resulting activation `x` an assembly?

The interconnection measure of `x` is $(interconnectionMeasure(x,A)).
That's because region A didn't go through any learning steps and regions begin with no recurrent connections; they only build them as needed by the learning rules.
`x` is a neuronal activation, but strictly speaking not an assembly.

However, this is not actually an important question.
An HTM region expects external stimulation. In this case, the external stimulation for B comes from A.
Correspondingly, we could have used another region to produce an external stimulation for A.
As long as we can assume:

1. some external stimulation
1. convergence of projection

we can use "input regions" that produce neuronal stimulations as input to others, without having to apply the learning rules themselves.
"""

# ╔═╡ Cell order:
# ╠═0d3bf5f6-1171-11ec-0fee-c73bb459dc3d
# ╟─1bb0fcfc-2d7a-4634-9c93-263050c56a55
# ╠═70471bdc-660e-442e-b92a-f486abd120a7
# ╟─7620c202-c6cf-44db-9cda-13642e28b45a
# ╟─043f8da8-f17a-4486-9c49-7d5ecc75457f
# ╠═bbaf0a64-2471-4106-a27c-9dd5a4f58c7c
# ╠═d4683829-b214-4d79-890d-bcc902bcef2b
# ╠═5b0c7174-dc2b-4b28-8cda-fc2e8a37151c
# ╟─334b271d-247c-465c-ae82-f91007a6d9d0
# ╠═4833f12f-3eac-407c-a9ce-0d1aea216077
# ╠═45d8e50b-8baa-4da2-8cd0-5c81d634c450
# ╟─91fa8319-1702-4cad-8ae8-0c1ed51a7bb8
# ╠═3ee589ed-0fe0-4328-88e8-d2fb6a98bf28
# ╠═6790a86a-3990-4c6a-878f-c18779f8d48d
# ╠═5458c6ae-ace2-4928-8a9b-ef919a1e97cb
# ╟─6b56422c-5f9b-41d8-a080-ef5ca3d7db7b
# ╠═3229da2a-92f3-4064-bb80-cbd9f5523d7d
# ╠═71f21302-04db-41aa-a259-f3be2b7bc271
# ╟─5e0ac810-1689-4bfb-88a8-85504cd821b6
# ╠═1015f629-9818-4dbb-b574-97c552e96164
# ╟─62d41be1-2970-48e1-b689-c2ecf1ab10ce
# ╠═d08cce9d-dd9c-4530-82ae-bf1db8be3281
# ╟─6a20715a-9dc9-461a-b6a2-f02522e277f0
# ╠═e63a5860-587c-4aff-91be-a894b3443943
# ╠═c866c71e-5dce-4af1-84bb-045815d1acb9
# ╠═75560584-1631-4c93-8808-e269d345e1c8
# ╠═456021aa-3dbf-4102-932f-43109905f9eb
# ╟─56e0da0b-8858-459a-9aae-0eba4797cc06
# ╠═cf83549c-03b1-4f7d-be29-d3a29da3e8f7
# ╠═85dfe3ed-cf70-4fde-a94a-f70c3fe4abf6
# ╟─2b6d959f-63bb-4d42-a34d-70d93f6a1636
# ╠═3a5e3aa0-e34e-457c-a405-9bc95cd88910
# ╠═5ec611f4-d3ea-4c5d-9221-4dcf2da3e18c
# ╟─3df40867-674b-405a-a05c-0733a4caaa67
# ╟─c3896446-3a24-413a-afab-6a67b07092f5
# ╠═dcbe4617-7314-42c1-87bf-57ca82554a20
# ╟─86e68710-1323-434e-b24b-d86b2719f53a
# ╠═da7a8cfb-986c-4598-8696-30c36ffb263d
# ╟─059f3e13-56f6-4dc6-9570-19c74996d1ef
# ╠═8e9003fa-c822-4508-9862-58a816d9242d
# ╠═d4cfbfe7-ba6f-4936-8854-8d49277657d2
# ╟─dfff3823-d750-40e1-9ddf-769cb2c7e575
# ╟─ed61ded0-d665-46a9-bed8-cd83cb0a545a
# ╟─5bd5049c-de0d-4838-9c82-9cef604e650e
# ╟─b886095d-d449-4334-99cf-44b800bb4fc4
# ╠═8fdacada-55df-4abd-9501-7405e608529b
