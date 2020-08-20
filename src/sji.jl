module sji

using Parameters
using JSON
using HTTP
using Dates

@with_kw struct Socrates
    #=
    Construct an authenticated Socrates client
    **kwargs:
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
        params = Dict(
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
        response = JSON.parse(String(r.body))
        if r.status == 200
            push!(headers, ("Authorization"=>"Token "*response["token"]))
        else
            error("failed to get token: return code: "*string(r.status)*", expected 200: response: "*response)
        end
        new(log_level, protocol, host, username, password, verify, headers)
    end
end

function push_raw_data(c, name, records)
    url = c.protocol*"://"*c.host*"/archimedes/datasource"
    params = JSON.json(Dict(
        "operation"=>"push_raw_data",
        "name"=>name,
        "records"=>records
    ))
    println(params)
    r = HTTP.post(
        url,
        c.headers,
        params,
        require_ssl_verification = c.verify
    )
    response = JSON.parse(String(r.body))
    if r.status == 200
        return true, response
    else
        return r.status, response
    end
end

function get_raw_data(c, name, key, time_start, time_end)
    url = c.protocol*"://"*c.host*"/archimedes/datasource"
    params = Dict(
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
    println(r.body)
    response = JSON.parse(String(r.body))
    if r.status == 200
        return true, response
    else
        return r.status, response
    end
end

end # module
