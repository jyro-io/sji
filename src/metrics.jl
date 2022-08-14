#=
metrics.jl
  set of algorithms for transforming input parameters into output metric::Float64
=#

# TODO: this can definitely be done more elegantly - I think :symbols is probably it
# map string input to algorithm call
function calc_metric(m::String, p::Dict, r::DataFrameRow)::Float64
  if m == "weighted_average"
    return weighted_average(p, r)
  elseif m == "bid_ask_spread"
    return bid_ask_spread(p, r)
  end
end

function weighted_average(p::Dict, r::DataFrameRow)::Float64
  t = 0.0
  for k in keys(p)
    t = t+(r[k]*p[k])
  end
  return round(t/sum(values(p)); digits=2)
end

function bid_ask_spread(p::Dict, r::DataFrameRow)::Float64
  return round(r[p["top"]]-r["bottom"]; digits=2)
end

function average(x::Float64, y::Float64)::Float64
  return round((x+y)/2; digits=2)
end
