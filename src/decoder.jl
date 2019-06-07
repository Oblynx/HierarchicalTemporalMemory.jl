struct SDRClassifier
  predictionSize::Int
  targetSize::Int
  α::Float32
  W::Matrix{Float32}
  history_pred::Matrix{Float32}
end
SDRClassifier(predictionSize,targetSize; α,buffer_length)=
    SDRClassifier(predictionSize,targetSize,α,
        zeros(targetSize,predictionSize), zeros(targetSize,buffer_length))

"""
    predict!(classifier::SDRClassifier, Π,target::Int; enable_learning=true)=

Predict probability that the output represents each bucket of an arithmetic encoder.
0<=predict!<=1
"""
predict!(classifier::SDRClassifier, Π,target::Int; enable_learning=true)=
    predict!(classifier, Π,bitarray(target,classifier.targetSize), enable_learning=enable_learning)
function predict!(classifier::SDRClassifier, Π,target::BitArray{1}; enable_learning=true)
  A(Π)= classifier.W*Π
  saturate(x)= isnan(x) ? 1 : x
  sumsat(x)= ( s= sum(x); isinf(s) ? maximum(x) : s )
  nonlinearity(A)= saturate.(ℯ.^A ./ sumsat(ℯ.^A))
  adapt()= -classifier.α .* (classifier.history_pred[:,end] .- target)*Π[Π]'
  circshift!(history,prediction)= begin
    history[:,2:end].= history[:,1:end-1]
    history[:,1].= prediction
  end
  prediction= Π|>A|>nonlinearity
  enable_learning &&
      ( classifier.W[:,Π]+= adapt() )
  circshift!(classifier.history_pred,prediction)
  return prediction
end
"""
    reverse_simpleArithmetic(bucketProbDist, algorithm,params)

Reverses the simple arithmetic encoder, given the same parameters.
Inputs a probability distribution across all buckets and collapses it to a single arithmetic
value, representing the most likely estimation in the timeseries' domain (like a defuzzifier)

# Arguments
- bucketProbDist [nbucket]: discrete probability of each bucket [0-1]
- algorithm: {'mean','mode','highmean'} 'highmean' is the mean of the highest-estimated values
"""
function reverse_simpleArithmetic(bucketProbDist::Vector, algorithm,params)
  bucketL= params.range / (2*params.buckets)
  bucketCenter= (params.in_min + bucketL .+ 2 .* (0:params.buckets-1) .* bucketL)#|> collect
  # normalize
  bucketProbDist= (bucketProbDist .+ eps(1/length(bucketCenter))) ./ sum(bucketProbDist)
  # Only the likeliest prediction, if it stands out
  if algorithm == "mode"
    if maximum(bucketProbDist) - minimum(bucketProbDist) > 0.2
      mostLikely= bucketCenter[findmax(bucketProbDist)[2]]
    else
      mostLikely= bucketCenter'bucketProbDist
    end
  # Mean of the entire distribution
  elseif algorithm == "mean"
    mostLikely= bucketCenter'bucketProbDist
  # Mean of the most likely predictions (like "mean", but filtering)
  elseif algorithm == "highmean"
    highprob= bucketProbDist .>= quantile(bucketProbDist,0.85)
    bucketProbDist[highprob].= bucketProbDist[highprob] ./ sum(bucketProbDist[highprob])
    mostLikely= bucketCenter[highprob]'bucketProbDist[highprob]
  else
    error("[reverse_simpleArithmetic] Algorithm $algorithm doesn't exist")
  end
  return mostLikely
end
