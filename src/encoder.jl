# ## Encoders

function encode_simpleArithmetic(x; encoder_size,in_max,in_min,buckets,range,w)
  b= floor(Int, (x-in_min) .* buckets./range) +1
  sdr= falses(encoder_size)
  sdr[b:b+w-1].= true
  sdr,b
end
function encode_powerDay(power,time,wkend; power_p,time_p,wkend_p)
  sdr_power,bucket= encode_simpleArithmetic(power; power_p...)
  sdr_time,_= encode_simpleArithmetic(time; time_p...)
  sdr_wkend,_= encode_simpleArithmetic(wkend; wkend_p...)
  [sdr_power;sdr_time;sdr_wkend], bucket
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
initenc_powerDay(power,time,wkend; encoder_size, w)= (
  power_p= initenc_simpleArithmetic(power,encoder_size[1],w[1]),
  time_p=  initenc_simpleArithmetic(time,encoder_size[2],w[2]),
  wkend_p= initenc_simpleArithmetic(wkend,encoder_size[3],w[3])
)
