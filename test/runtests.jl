using sji
using Test
using Dates
using JSON
using DataFrames

@testset "sji.jl" begin
  data = DataFrame(
    :close => rand(Int, 100)
  )
  result = sji.exponential_moving_average!(
    data,
    3,
    "close"
  )
  @debug "result" result
  result::AbstractDataFrame
  hasproperty(result, :ema_3)
  @test length(result.ema_3) == length(data[:, :close])
end
