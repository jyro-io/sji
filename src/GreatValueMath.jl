module GreatValueMath

using Statistics
using DataFrames

function min_max_feature_scale_normalization(data::DataFrame, field::String)::DataFrame
  ma = maximum(data[:, field])
  mi = minimum(data[:, field])
  for (index, i) in enumerate(eachrow(data))
    data[index, field] = (i[field] - mi)/(ma - mi)
  end
  return data
end

function min_max_feature_scale_normalization(data::Vector)::Vector{Float64}
  data = convert(Vector{Float64}, data)
  min_val = data[1]
  max_val = data[1]
  for i in 2:n
    if data[i] < min_val
      min_val = data[i]
    elseif data[i] > max_val
      max_val = data[i]
    end
  end
  return (data .- min_val) ./ (max_val .- min_val)
end

function min_max_feature_scale_normalization(data::Vector, a::Float64, b::Float64)::Vector{Float64}
  data = convert(Vector{Float64}, data)
  ma = maximum(data)
  mi = minimum(data)
  for (index, i) in enumerate(data)
    data[index] = a+(((i - mi) * (b - a)) / (ma - mi))
  end
  return data
end

function theil_sen(data::DataFrame, x::String)
  n = nrow(data)
  # independent variable vector
  xᵢ = data[!, x]
  slopes = zeros(n, n)
  for i in 1:n
    for j in i+1:n
      slopes[i, j] = (xᵢ[j] - xᵢ[i]) / (j - i)
    end
  end
  return median(vec(slopes))
end

function linear_least_squares(data::DataFrame, x::String, y::String)
  n = nrow(data)
  # independent variable vector
  xᵢ = data[!, x]
  # dependent variable vector
  yᵢ = data[!, y]
  xbar = mean(xᵢ)
  ybar = mean(yᵢ)
  sumxy = sum(xᵢ .* yᵢ) - n * xbar * ybar
  sumxx = sum(xᵢ .* xᵢ) - n * xbar * xbar
  slope = sumxy / sumxx
  yintercept = ybar - slope * xbar
  variance = sum((xᵢ .- slope * xᵢ .- yintercept) .^ 2) / (n - 2)
  return variance, slope, yintercept
end

end # module
