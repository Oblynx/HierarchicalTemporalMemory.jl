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
predict!(classifier::SDRClassifier, Π,target::Int; enable_learning=true)=
    predict!(classifier, Π,bitarray(target,classifier.targetSize), enable_learning=enable_learning)
function predict!(classifier::SDRClassifier, Π,target::BitArray{1}; enable_learning=true)
  A(Π)= classifier.W*Π
  nonlinearity(A)= ℯ.^A ./ sum(ℯ.^A)
  adapt()= -classifier.α .* (classifier.history_pred[:,end] .- target)*Π[Π]'
  circshift!(history,prediction)= begin
    history[:,2:end].= history[:,1:end-1]
    history[:,1].= prediction
  end
  prediction= Π|>A|>nonlinearity
  classifier.W[:,Π]+= adapt()
  circshift!(classifier.history_pred,prediction)
  return prediction
end
