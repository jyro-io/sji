__precompile__(true)
module sji

using Parameters
using JSON
using HTTP
using Dates

@with_kw struct Socrates
    #=
    Construct an authenticated Socrates client
    keyword arguments:
        log_level <int> log output threshold level
        protocol <string> HTTP/HTTPS
        host <string> Socrates host
        username <string> Socrates username
        password <string> Socrates password
        verify <bool> SSL verify
    =#

    log_level::UInt8 = 3
    protocol::String = "https"
    host::String = "api.jyro.io"
    username::String
    password::String
    verify::Bool = true
    headers::Array = ["Content-Type" => "application/json"]

    function Socrates(log_level, protocol, host, username, password, verify, headers)
        url = protocol*"://"*host*"/auth"
        params = Dict{String,String}(
            "username"=>username,
            "password"=>password
        )
        r = HTTP.post(
            url,
            headers,
            JSON.json(params),
            require_ssl_verification = verify,
            readtimeout = 5,
            retries = 1
        )
        response = JSON.parse(String(r.body))::Dict
        if r.status == 200
            push!(headers, ("Authorization"=>"Token "*response["token"]))
        else
            error("failed to get token: return code: "*string(r.status)*", expected 200: response: "*response)
        end
        new(log_level, protocol, host, username, password, verify, headers)
    end
end

struct SocratesResponse
    status::Bool
    response
end

function push_raw_data(c::Socrates, name::String, records::Array)::SocratesResponse
    #=
    Push raw data to Socrates

    positional arguments:
        c <Socrates> client type
        name <String> datasource name
        records <Array(Dict())>
    =#
    url = c.protocol*"://"*c.host*"/archimedes/datasource"
    params = JSON.json(Dict(
        "operation"=>"push_raw_data",
        "name"=>name,
        "records"=>records
    ))
    r = HTTP.post(
        url,
        c.headers,
        params,
        require_ssl_verification = c.verify
    )
    response = JSON.parse(String(r.body))
    if r.status == 200
        return SocratesResponse(true, response::Dict)
    else
        return SocratesResponse(false, response::Dict)
    end
end

function get_raw_data(c::Socrates, name::String, key::String, time_start::String, time_end::String)::SocratesResponse
    #=
    Get raw data from Socrates

    positional arguments:
        c <Socrates> client type
        name <String> datasource name
        key <String> iter_field key
        time_start <String> time series start
        time_end <String> time series end
    =#

    url = c.protocol*"://"*c.host*"/archimedes/datasource"
    params = Dict{String,String}(
        "operation"=>"get_raw_data",
        "name"=>name,
        "key"=>key,
        "start"=>time_start,
        "end"=>time_end
    )
    r = HTTP.post(
        url,
        c.headers,
        JSON.json(params),
        require_ssl_verification = c.verify
    )
    response = JSON.parse(String(r.body))
    if r.status == 200
        return SocratesResponse(true, response::Dict)
    else
        return SocratesResponse(false, response::Dict)
    end
end

function get_definition(c::Socrates, api::String, api_module::String, name::String)::SocratesResponse
    #=
    Get a JSON definition record from a specified api.module endpoint

    positional arguments:
        c <Socrates> client type
        api <String> [archimedes,socrates]
        api_module <String> endpoint to request
        name <String> definition name
    =#

    url = c.protocol*"://"*c.host*"/"*api*"/"*api_module
    params = Dict{String,String}(
        "operation"=>"get",
        "name"=>name
    )
    r = HTTP.post(
        url,
        c.headers,
        JSON.json(params),
        require_ssl_verification = c.verify
    )
    response = JSON.parse(String(r.body))
    if r.status == 200
        return SocratesResponse(true, response::Dict)
    else
        return SocratesResponse(false, response::Dict)
    end
end

function get_iteration_set(c::Socrates, name::String)::SocratesResponse
    #=
    Get defined set of keys from configured datasource to parallelize processing

    positional arguments:
        c <Socrates> client type
        name <String> definition name
    =#

    url = c.protocol*"://"*c.host*"/archimedes/scraper"
    params = Dict{String,String}(
        "operation"=>"get_iteration_set",
        "name"=>name
    )
    r = HTTP.post(
        url,
        c.headers,
        JSON.json(params),
        require_ssl_verification = c.verify
    )
    response = JSON.parse(String(r.body))
    if r.status == 200
        return SocratesResponse(true, JSON.parse(response["data"])::Array)
    else
        return SocratesResponse(false, response::Dict)
    end
end

export Socrates, SocratesResponse, get_iteration_set, push_raw_data, get_raw_data, get_definition, get_iteration_set

end # module
