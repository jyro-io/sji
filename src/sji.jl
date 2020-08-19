module sji

using Parameters
using JSON
using HTTP

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

    log_level::Int = 3
    protocol::String = "https"
    host::String = "api.jyro.io"
    username::String
    password::String
    verify::Bool = true
    headers = [
        "Content-Type" => "application/json"
    ]

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
            retries = 2
        )
        if r.status == 200
            response = JSON.parse(String(r.body))
            push!(headers, ("Authorization"=>"Token "*response["token"]))
        else
            error("failed to get token: return code was "*string(r.status)*", expected 200")
        end
        new(log_level, protocol, host, username, password, verify, headers)
    end
end

end
