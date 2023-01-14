#=
metrics.jl
  set of algorithms for transforming input parameters into output metric::Float64
=#

# TODO: this can definitely be done more elegantly - I think :symbols is probably it
# map string input to algorithm call for
# DataFrameRow inputs
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

# TODO: generalize to arbitrary intervals,
#       currently only days are supported.
function sma(p::Dict, d::DataFrame)::DataFrame
  # calculate SMA
  for period in p["periods"]
    pf = "sma_"*string(period)  # period field
    # find the period size for this dataset
    ps = 0
    for (i, r) in enumerate(eachrow(d))
      if <(r[p["time_field"]], d[begin, :][p["time_field"]] + Dates.Day(period))
        ps = i  # period size
        break
      end
    end
    if ==(0, ps)
      return false
    end
    # calculate SMA
    pst = 1  # period start
    pe = pst + ps  # period end
    for (i, r) in enumerate(eachrow(d[pe:end, :]))
      d[i, pf] = sum(d[pst:pe, :][p["data_field"]]) / ps
    end
  end
  # remove rows without SMA fields
  for period in p["periods"]
    pf = "sma_"*string(period)
    for (i, r) in enumerate(eachrow(d))
      if ==(haskey(r, pf), false)
        delete!(d, i)
      end
    end
  end
  return d
end
