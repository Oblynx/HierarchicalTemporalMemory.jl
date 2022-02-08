using HierarchicalTemporalMemory, Test
plot_enabled= false

## Create Regions
using Random
Random.seed!(0)

# Parameters
Nin= 1e3|> Int        		# input size
Nn= 4e5             	    # number of neurons in each area
k= 20                 		# neurons per minicolumn
thresholds= ( 				# calibrate how many dendritic inputs needed to fire
	tm_learn= 20,
	tm_activate= 25,
	tm_dendriteSynapses= 50,
)
learnrate= (
	p⁺= .06,
	p⁻= .02,
)
_Nc()= floor(Int,Nn/k) 		# number of minicolumns
sparsity()= 1/sqrt(_Nc());
params_input= (
	sp= HierarchicalTemporalMemory.SPParams(szᵢₙ=Nin, szₛₚ=_Nc(), s= sparsity(), prob_synapse=1e-3, enable_local_inhibit=false),
	tm= HierarchicalTemporalMemory.TMParams(Nc=_Nc(), k=k, p⁺_01= learnrate.p⁺, p⁻_01= learnrate.p⁻, θ_stimulus_learn=thresholds.tm_learn, θ_stimulus_activate=thresholds.tm_activate, synapseSampleSize=thresholds.tm_dendriteSynapses)
)
params_M= @set params_input.sp.szᵢₙ= params_input.tm.Nₙ

r= map(_-> Region(params_M.sp, params_M.tm), 1:4)

# Random inputs
a= (@chain bitrand(r[1].sp.params.szᵢₙ) r[1](_).active)

## Wire regions

plot_enabled && begin
	using GLMakie, GraphMakie, NetworkLayout
	GLMakie.activate!(); Makie.inline!(true);
end

# feedforward diamond-shaped network
# in --> r1 -a--> r2 --+-> r4
#            +--> r3 --+
n_composition= x -> @chain x begin
	r[1]()
	(a -> (
		r[2](a).active,
		r[3](a).active,
	))()
	reduce(.|, _)
	r[4](_).active
end

# Network adjacency matrix
n= Network(r[1:4], connect_forward= [
	0 1 1 0 0 0
	0 0 0 1 0 0
	0 0 0 1 0 0
	0 0 0 0 0 1
	1 0 0 0 0 0
	0 0 0 0 0 0
])
# Visualise network
plot_enabled && networkPlot(n, graphplot)

@testset "Signal propagation through network" begin
	reset!(n)
	t= [(n(a), deepcopy(n.region_α₋)) for _= 1:propagation_delay(n)+1]
	netoutput= map(t->t[1],t)
	regionstate= map(t->t[2], t)

	# t=2: Signal stable on region 1
	@test (regionstate[2] .== regionstate[1])[1] && all((regionstate[2] .!= regionstate[1])[2:end])
	# t=3: Signal stable on regions 1:3
	@test all((regionstate[3] .== regionstate[2])[1:3]) && all((regionstate[3] .!= regionstate[2])[4])
	# t=4: Signal stable on regions 1:4
	@test regionstate[4] == regionstate[3]
	# and the signal reaches the network output at t=3, stabilizing it.
	@test netoutput[2] != netoutput[1]
	@test netoutput[3] != netoutput[2]
	@test netoutput[4] == netoutput[3]
end

@testset "After settling, network output is the same as function composition" begin
	reset!(n)
	@test n(a) != n_composition(a)
	foreach(_ -> n(a), 1:propagation_delay(n))
	@test n(a) == n_composition(a)
end

@testset "Train network" begin
	reset!(n)
	# After propagation delay, the output shouldn't change.
	# Show that training the network changes the output.
	x_pre= last((n(a) for _= 1:propagation_delay(n)+1), 1)[1]
	t= [step!(n,a) for _= 1:2propagation_delay(n)+1]
	x_trained= last((n(a) for _= 1:propagation_delay(n)+1), 1)[1]
	# Expect only a small overlap
	@test count(x_pre .& x_trained) < (0.3count(x_pre))
end


## network with cycle: impossible to define with function composition
# in --> r1 --> r2 --> r3 --> out
#               +---<--+

# not functional for 1 instant
# I need a window
# describe state as the set of values at each wire

n_cy= Network(r[1:3], connect_forward= [
	0 1 0 0 0
	0 0 1 0 0
	0 1 0 0 1
	1 0 0 0 0
	0 0 0 0 0
])
plot_enabled && networkPlot(n_cy, graphplot)

step!(n_cy, a)

@testset "Signal propagation through network with cycle" begin
	reset!(n_cy)
	t= [(n_cy(a), deepcopy(n_cy.region_α₋)) for _= 1:propagation_delay(n_cy)+50]
	netoutput= map(t->t[1],t)
	regionstate= map(t->t[2], t)

	# t=2: Signal stable on region 1
	@test (regionstate[2] .== regionstate[1])[1] && all((regionstate[2] .!= regionstate[1])[2:end])
	# t=3: Signal stable only on region 1, region 2 changes due to feedback
	@test all((regionstate[3] .== regionstate[2])[1]) && all((regionstate[3] .!= regionstate[2])[2:end])

	# TODO: test eventual stability!
	# t=4: Signal stable on all regions
	#@test all((regionstate[4] .== regionstate[3])[1:3])
end