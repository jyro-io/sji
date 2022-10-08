using sji
using Test
using Dates
using JSON

@testset "sji.jl" begin
  socrates = sji.Socrates(
    protocol="https",
    host="socrates",
    username="test",
    password="iP6mp8PUJC70ioi3M9lX7YxP",
    verify=false
  )

  timestamp_format = "yyyy-mm-dd HH:MM:SS"

  push_before = Dates.now()
  record = [Dict(
    "test_key"=>"integration",
    "test_iter_field"=>"iter_value",
    "timestamp"=>Dates.format(now(), timestamp_format)
  )]
  sr = sji.push_raw_data(
    socrates,
    "test",
    record
  )
  if sr.status != true
    error("failed to push raw data: "*sr.response)
  end
  sleep(2)
  push_after = Dates.now()
  println(sr.response)

  sr = sji.get_raw_data(
    socrates,
    "iter_value",
    Dates.format(push_before, timestamp_format),
    Dates.format(push_after, timestamp_format);
    key="test"
  )
  if sr.status != true
    error("failed to get raw data: "*sr.response)
  end
  println(sr.response)

  sr = sji.get_definition(
    socrates,
    "archimedes",
    "datasource",
    "test"
  )
  if sr.status != true
    error("failed to get definition: "*sr.response)
  end
  println(sr.response)

  sr = sji.get_iteration_set(
    socrates,
    "test",
    "test"
  )
  if sr.status != true
    error("failed to get iteration set: "*sr.response)
  end
  println(sr.response)

  sr = sji.get_config(
    socrates,
    "archimedes",
    "test"
  )
  if sr.status != true
    error("failed to get config: "*sr.response)
  end
  println(sr.response)

  sr = sji.update_config(
    socrates,
    "archimedes",
    "test",
    Dict(
      "test_key"=>"test_value"
    )
  )
  if sr.status != true
    error("failed to update config: "*sr.response)
  end
  println(sr.response)
end
