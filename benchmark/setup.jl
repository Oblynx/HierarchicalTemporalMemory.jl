"""
`setupHTMexperiment(; inputDims,spDims,k, spParams,tmParams, dataFilepath)` initializes an HTM system
for a quick experiment with reasonable defaults.
It assumes the power/day/wkend data encoding.

# Returns

- `SpatialPooler`
- `TemporalMemory`
- `data`
- `z,bucket = encode(data,t)`
- `decoder`
"""
function setupHTMexperiment(;
      inputDims= ((15,6,3).*25,),
      spDims= (1800,),
      k= 8,
      spParams= SPParams(
            szᵢₙ= map(sum,inputDims), szₛₚ=spDims,
            γ=1000,
            s=0.03,
            prob_synapse=0.85,
            θ_stimulus_activate=5,
            p⁺_01= 0.20,
            p⁻_01= 0.12,
            β=3,
            Tboost=350,
            enable_local_inhibit=false,
            enable_boosting=true),
      tmParams= TMParams(
            Nc=prod(spDims),
            k=k,
            θ_stimulus_activate=14,
            θ_stimulus_learn=12,
            synapseSampleSize=35,
            p⁺_01=0.24,
            p⁻_01=0.08,
            LTD_p⁻_01= 0.012
          ),
      dataFilepath= "../test/test_data/gym_power_benchmark-extended.csv")
  data= CSV.read(dataFilepath)
  encParams= initenc_powerDay(data.power_hourly_kw, data.hour, data.is_weekend,
                  encoder_size=inputDims[1], w=(34,35,35))
  decoder= SDRClassifier(tmParams.Nₙ,encParams.power_p.buckets,
                    α=0.09, buffer_length=1)

  encode= (data,t) -> encode_powerDay(data.power_hourly_kw[t], data.hour[t], data.is_weekend[t];
                       encParams...)
  (SpatialPooler(spParams),
  TemporalMemory(tmParams),
  data, encode, decoder)
end