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
function simple_moving_average(p::Dict, data::DataFrame)::DataFrame
  # calculate SMA
  for period in p["periods"]
    pf = "sma_"*string(period)  # period field
    # find the period size for this dataset
    ps = 0
    for (index, row) in enumerate(eachrow(data))
      if >=(row[p["time_field"]], data[begin, p["time_field"]] + Dates.Day(period))
        ps = index  # period size
        break
      end
    end
    if ==(0, ps)
      return false
    end
    # calculate SMA
    pst = 1  # period start
    pe = pst + ps  # period end
    s = nrow(data)  # size of dataset
    while true
      if <=(s, pe)
        pe = s
      end
      if ==(s-1, pst)
        break
      end
      data[pe, pf] = sum(data[pst:pe, p["data_field"]]) / (pe - pst)
      pst += 1
      pe = pst + ps
    end
  end
  for period in p["periods"]
    pf = "sma_"*string(period)
    # remove invalid values
    indexes = []
    for (index, row) in enumerate(eachrow(data))
      if ==(0.0, row[pf])
        append!(indexes, index)
      end
    end
    delete!(data, indexes)
  end
  return data
end
