__precompile__(true)
module sji

using Parameters
using JSON
using HTTP
using Dates
using Mongoc
using DataFrames

include("metrics.jl")

@with_kw struct Socrates
  #=
  Construct an authenticated Socrates client
  keyword arguments:
    protocol <string> HTTP/HTTPS
    host <string> Socrates host
    username <string> Socrates username
    password <string> Socrates password
    verify <bool> SSL verify
  =#

  protocol::String = "https"
  host::String = "api.jyro.io"
  username::String
  password::String
  verify::Bool = true
  headers::Array = ["Content-Type" => "application/json"]

  function Socrates(protocol, host, username, password, verify, headers)
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
    new(protocol, host, username, password, verify, headers)
  end
end

struct SocratesResponse
  status::Bool
  response
end

function get_metadata(datasource, scraper_definition)::SocratesResponse
  metrics = Dict()
  fields = []
  scraper_definition["rules"]::Array
  # scan definition rules for fields
  for rule in scraper_definition["rules"]
    rule::Dict
    if ==(haskey(rule, "field"), true)
      if ===(typeof(rule["field"]), String)
        if ===(findfirst(x->x==rule["field"], fields), nothing)
          push!(fields, rule["field"])
        end
      end
    end
  end
  # scan datasource ETL pipeline for metrics
  datasource["metadata"]["etl"]::Array
  for op in datasource["metadata"]["etl"]
    op::Dict
    if ==(op["operation"], "metric")
      if ==(op["pull_fields"], true)
        for k in keys(op["parameters"])
          if ===(findfirst(x->x==k, fields), nothing)
            push!(fields, k)
          end
        end
      end
      # metrics can be used multiple times in the pipeline;
      # the last one will be the final form
      metrics[op["name"]] = op["parameters"]
    end
  end
  if ==(isempty(metrics), true) || ==(length(fields), 0)
    return SocratesResponse(false, (metrics, fields))
  end
  return SocratesResponse(true, (metrics, fields))
end

function etl(datasource::Dict, data::DataFrame)::DataFrame
  if ==(haskey(datasource["metadata"], "etl"), true)
    for op in datasource["metadata"]["etl"]
      if ==(op["operation"], "metric")
        for (i, d) in enumerate(eachrow(data))
          data[i, op["name"]] = calc_metric(op["name"], op["parameters"], d)
        end
      end
    end
  end
  return data
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

function get_raw_data(c::Socrates, name::String, time_start::String, time_end::String; key=nothing, topic=nothing)::SocratesResponse
  #=
  Get raw data from Socrates

  positional arguments:
    c <Socrates> client type
    name <String> datasource name
    key/topic <String> key to find data
    time_start <String> time series start
    time_end <String> time series end
  =#

  url = c.protocol*"://"*c.host*"/archimedes/datasource"
  params = Dict{String,String}(
    "operation"=>"get_raw_data",
    "name"=>name,
    "start"=>time_start,
    "end"=>time_end
  )
  if !=(key, nothing) && !=(topic, nothing)
    return SocratesResponse(false, Dict("error"=>"key and topic parameters are mutually exclusive"))
  elseif key::String
    params["key"] = key
  elseif topic::String
    params["topic"] = topic
  end
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

function get_iteration_set(c::Socrates, name::String, datasource::String)::SocratesResponse
  #=
  Get defined set of keys from configured datasource to parallelize processing

  positional arguments:
    c <Socrates> client type
    name <String> scraper definition name
    datasource <String> datasource name
  =#

  url = c.protocol*"://"*c.host*"/archimedes/scraper"
  params = Dict{String,String}(
    "operation"=>"get_iteration_set",
    "name"=>name,
    "datasource"=>datasource
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

function push_to_scrapeindex(c::Socrates, record::Dict)::SocratesResponse
  #=
  Get fields for defined metric

  positional arguments:
    c <Socrates> client type
    name <String> metric name
  =#

  url = c.protocol*"://"*c.host*"/archimedes/scrapeindex"
  r = HTTP.post(
    url,
    c.headers,
    JSON.json(record),
    require_ssl_verification = c.verify
  )
  response = JSON.parse(String(r.body))
  if r.status == 200
    return SocratesResponse(true, nothing)
  else
    return SocratesResponse(false, response::Dict)
  end
end

function get_unreviewed_index_records(c::Socrates, name::String, datasource::String)::SocratesResponse
  #=
  Get index records in state "new"

  positional arguments:
    c <Socrates> client type
    name <String> metric name
  =#

  url = c.protocol*"://"*c.host*"/archimedes/scraper"
  params = Dict{String,String}(
    "operation"=>"get_unreviewed_index_records",
    "name"=>name,
    "datasource"=>datasource
  )
  r = HTTP.post(
    url,
    c.headers,
    JSON.json(params),
    require_ssl_verification = c.verify
  )
  response = JSON.parse(String(r.body))
  if r.status == 200
    return SocratesResponse(true, nothing)
  else
    return SocratesResponse(false, response::Dict)
  end
end

function get_config(c::Socrates, api::String, key::String)::SocratesResponse
  #=
  Get a JSON definition record from a specified api.module endpoint

  positional arguments:
    c <Socrates> client type
    api <String> [archimedes,socrates]
    key <String> configuration key to query
  =#

  url = c.protocol*"://"*c.host*"/"*api*"/_config"
  params = Dict{String,String}(
    "operation"=>"get",
    "key"=>key
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

function update_config(c::Socrates, api::String, key::String, config::Dict)::SocratesResponse
  #=
  Get a JSON definition record from a specified api.module endpoint

  positional arguments:
    c <Socrates> client type
    api <String> [archimedes,socrates]
    key <String> configuration key to query
    config <Dict> configuration to update
  =#

  url = c.protocol*"://"*c.host*"/"*api*"/_config"
  params = Dict(
    "operation"=>"update",
    "key"=>key,
    "config"=>config
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

function get_mongo_records(collection::Mongoc.Collection, include::Tuple, exclude::Tuple, bson_options::Mongoc.BSON)::DataFrame
  data = DataFrame()
  records = collect(Mongoc.find(collection, options=bson_options))
  for (index, doc) in enumerate(records)
    doc = Mongoc.as_dict(doc)
    for field in exclude
      delete!(doc, field)
    end
    # init columns
    if index == 1
      for field in include
        # fast generic type detection
        data[!, field] = Array{typeof(doc[field]),1}()
      end
    end
    push!(data, doc)
  end
  return data
end

function connect_to_datasource(s::Socrates, name::String)::Mongoc.Client
  sr = get_definition(
    s,
    "archimedes",
    "datasource",
    name
  )
  if sr.status != true
    error("failed to get datasource definition: "*sr.response)
  end
  ds = sr.response
  return Mongoc.Client("mongodb://"*ds["username"]*":"*ds["password"]*"@"*ds["host"]*"/?authSource=admin")
end

export Socrates
export SocratesResponse
export get_metadata
export push_raw_data
export get_raw_data
export get_definition
export get_iteration_set
export get_metric_fields
export push_to_scrapeindex
export get_unreviewed_index_records
export get_config
export update_config
export get_mongo_records
export connect_to_datasource

end # module
