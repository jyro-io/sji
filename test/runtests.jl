using sji
using Test
using Dates
using JSON

@testset "sji.jl" begin
    socrates = sji.Socrates(
        protocol="http",
        host="localhost",
        username="test",
        password="iP6mp8PUJC70ioi3M9lX7YxP",
        verify=false
    )

    timestamp_format = "yyyy-mm-dd HH:MM:SS.s"

    push_before = Dates.now()
    record = [Dict(
        "test_key"=>"integration",
        "timestamp"=>Dates.format(now(), timestamp_format)
    )]
    status, response = sji.push_raw_data(
        socrates,
        "test",
        record
    )
    if status != true
        error("failed to push raw data: "*response)
    end
    push_after = Dates.now()

    status, response = sji.get_raw_data(
        socrates,
        "test",
        "integration",
        Dates.format(push_before, timestamp_format),
        Dates.format(push_after, timestamp_format)
    )
    if status != true
        error("failed to get raw data: "*response)
    end

    status, response = sji.get_definition(
        socrates,
        "archimedes",
        "datasource",
        "test"
    )
    if status != true
        error("failed to get definition: "*response)
    end
end
