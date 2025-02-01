using sji
using Test
using Dates
using JSON
using DataFrames

@testset "sji.jl" begin
  result = sji.exponential_moving_average!(
    DataFrame(
      :close => rand(Int, 100)
    ),
    3,
    "close"
  )
  @debug "result" result
  result::AbstractDataFrame
  hasproperty(result, :ema_3)
end
