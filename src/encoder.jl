# ## Encoders

function encode_simpleArithmetic(x; encoder_size,in_max,in_min,buckets,range,w)
  b= floor(Int, (x-in_min) .* buckets./range) +1
  sdr= falses(encoder_size)
  sdr[b:b+w-1].= true
  sdr
end


# ## Encoder parameter generators

function initenc_simpleArithmetic(ts; encoder_size,buckets=0,w=0)
  in_max= maximum(ts); in_min= minimum(ts)
  range= in_max - in_min +10*eps(in_max)
  if buckets>0
    w= prod(encoder_size) - buckets +1
  elseif w>0
    buckets= prod(encoder_size) - w +1;
  else
    error("[initenc_simpleArithmetic]: either buckets or w must be provided")
  end
  (in_max=in_max, in_min=in_min, range=range, buckets=buckets, w=w, encoder_size=encoder_size)
end
