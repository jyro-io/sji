__precompile__(true)
module sji

using Parameters
using JSON
using HTTP
using Dates
using Mongoc
using DataFrames

@with_kw struct Socrates
  #=
  Construct an authenticated Socrates client
  keyword arguments:
    protocol <string> HTTP/HTTPS
    host <string> Socrates host
    username <string> Socrates username
    password <string> Socrates password
    verify <bool> SSL verify
    conf <SSLConfig> SSL configuration
    headers <Array> HTTP headers
  =#

  protocol::String = "https"
  host::String = "api.jyro-io.ddns.net"
  username::String
  password::String
  verify::Bool = true
  headers::Array = ["Content-Type" => "application/json"]
  debug::Int32 = 1

  function Socrates(protocol, host, username, password, verify, headers, debug)
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
    new(protocol, host, username, password, verify, headers, debug)
  end
end

struct SocratesResponse
  status::Bool
  response
end

function get_predictive_model(c::Socrates, datasource::String, definition::String)::SocratesResponse
  #=
  Get a trained predictive model for a (datasource, pattern) pair from Archimedes

  positional arguments:
    c <Socrates> client type
    datasource <String> datasource name
    definition <String> scraper definition name
  =#

  url = c.protocol*"://"*c.host*"/archimedes/model"
  params = Dict{String,String}(
    "operation"=>"get",
    "datasource"=>datasource,
    "definition"=>definition
  )
  r = HTTP.post(
    url,
    c.headers,
    JSON.json(params),
    require_ssl_verification = c.verify,
  )
  response = JSON.parse(String(r.body))
  if r.status == 200
    return SocratesResponse(true, response::Dict)
  else
    return SocratesResponse(false, response::Dict)
  end
end

function update_predictive_model(c::Socrates, datasource::String, definition::String, model::String)::SocratesResponse
  #=
  add/update predictive model

  positional arguments:
    c <Socrates> client type
    datasource <String> datasource name
    definition <String> scraper definition name
    model <String> model -> BSON -> string
  =#

  # check for existing model
  if get_predictive_model(c, datasource, definition).status
    operation = "update"
  else
    operation = "add"
  end

  url = c.protocol*"://"*c.host*"/archimedes/model"
  params = Dict{String,String}(
    "operation"=>operation,
    "datasource"=>datasource,
    "definition"=>definition,
    "model"=>model
  )
  r = HTTP.post(
    url,
    c.headers,
    JSON.json(params),
    require_ssl_verification = c.verify,
  )
  response = JSON.parse(String(r.body))
  if r.status == 200
    return SocratesResponse(true, response::Dict)
  else
    return SocratesResponse(false, response::Dict)
  end
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
    require_ssl_verification = c.verify,
  )
  response = JSON.parse(String(r.body))
  if r.status == 200
    return SocratesResponse(true, response::Dict)
  else
    return SocratesResponse(false, response::Dict)
  end
end

function get_raw_data(c::Socrates, name::String, time_start, time_end; key=nothing, topic=nothing)::SocratesResponse
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
  params = Dict{String,Any}(
    "operation"=>"get_raw_data",
    "name"=>name,
    "start"=>time_start,
    "end"=>time_end
  )
  if !=(key, nothing) && !=(topic, nothing)
    return SocratesResponse(false, Dict("error"=>"key and topic parameters are mutually exclusive"))
  elseif ==(String, typeof(key))
    params["key"] = key
  elseif ==(String, typeof(topic))
    params["topic"] = topic
  end
  r = HTTP.post(
    url,
    c.headers,
    JSON.json(params),
    require_ssl_verification = c.verify,
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
    require_ssl_verification = c.verify,
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
    require_ssl_verification = c.verify,
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
    require_ssl_verification = c.verify,
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
    require_ssl_verification = c.verify,
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
    require_ssl_verification = c.verify,
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
    require_ssl_verification = c.verify,
  )
  response = JSON.parse(String(r.body))
  if r.status == 200
    return SocratesResponse(true, response::Dict)
  else
    return SocratesResponse(false, response::Dict)
  end
end

function get_mongo_records(collection::Mongoc.Collection, filter::Mongoc.BSON, bson_options::Mongoc.BSON; include::Tuple=())::DataFrame
  data = DataFrame()
  records = collect(Mongoc.find(collection, filter, options=bson_options))
  for (index, record) in enumerate(records)
    record = Mongoc.as_dict(record)
    fields = nothing
    if <(0, length(include))
      fields = include
      for field in keys(record)
        if field ∉ fields
          delete!(record, field)
        end
      end
    elseif ==(0, length(include))
      fields = keys(record)
    else
      return false
    end
    # init columns
    if index == 1
      for field in fields
        # fast generic type detection
        data[!, field] = Array{typeof(record[field]),1}()
      end
    end
    push!(data, record)
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
  if ==("kafka", ds["type"])
    if ∈("options", keys(ds))
      return Mongoc.Client("mongodb://"*ds["replication"]["username"]*":"*ds["replication"]["password"]*"@"*ds["replication"]["host"]*"/"*ds["replication"]["options"])
    else
      return Mongoc.Client("mongodb://"*ds["replication"]["username"]*":"*ds["replication"]["password"]*"@"*ds["replication"]["host"])
    end
  elseif ==("mongo", ds["type"])
    if ∈("options", keys(ds))
      return Mongoc.Client("mongodb://"*ds["username"]*":"*ds["password"]*"@"*ds["host"]*"/"*ds["options"])
    else
      return Mongoc.Client("mongodb://"*ds["username"]*":"*ds["password"]*"@"*ds["host"])
    end
  end
end

function get_metadata(datasource::Dict, scraper_definition::Dict)::SocratesResponse
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
      # metrics can be used multiple times in the pipeline,
      # allowing recursive metric calculations;
      # the last one will be the final form
      metrics[op["name"]] = op["parameters"]
    end
  end
  # split SMA into constituent metrics according to configured periods
  if haskey(metrics, "sma")
    for op in datasource["metadata"]["etl"]
      if ==(op["name"], "sma")
        for period in op["parameters"]["periods"]
          metrics["sma_"*string(period)] = op["parameters"]
        end
      end
    end
    delete!(metrics, "sma")
  end
  if ==(isempty(metrics), true) || ==(length(fields), 0)
    return SocratesResponse(false, (metrics, fields))
  end
  return SocratesResponse(true, (metrics, fields))
end

function etl!(datasource::Dict, data::DataFrame; prune::Bool=true)
  if ==(haskey(datasource["metadata"], "etl"), true)
    for op in datasource["metadata"]["etl"]
      if ==(op["operation"], "metric")
        if ==(op["name"], "sma")
          data = simple_moving_average!(op["parameters"], data, prune)
          if ==(false, data)
            return false
          end
        else
          for (i, d) in enumerate(eachrow(data))
            data[i, op["name"]] = calc_metric(op["name"], op["parameters"], d)
          end
        end
      end
    end
  end
  return data
end

function slice_dataframe_by_time_interval(data::DataFrame, field::String, start::DateTime, stop::DateTime)
  if >(stop, start)
    bindex = nothing
    eindex = nothing
    for (index, row) in enumerate(eachrow(data))
      row[field]::DateTime
      if >=(start, row[field])
        bindex = index
      elseif >=(stop, row[field])
        eindex = index
      end
    end
    if !=(nothing, bindex) && !=(nothing, eindex)
      return data[bindex:eindex, :]
    else 
      return false
    end
  else
    return false
  end
end

struct OHLCInterval
  interval::Int64
  unit::String
end

function get_ohlc_interval(destination::OHLCInterval)
  if ==("m", destination.unit)
    interval = Dates.Minute(destination.interval)
  elseif ==("h", destination.unit)
    interval = Dates.Hour(destination.interval)
  elseif ==("d", destination.unit)
    interval = Dates.Day(destination.interval)
  else
    error("invalid unit, expecting [m,h,d]")
  end
  return interval
end

function convert_ohlc_interval(data::DataFrame, time_field::String, fields::Array, destination::OHLCInterval)
  converted = empty(data)
  base_interval = get_ohlc_interval(destination)
  i = 1
  while true
    slice = false
    interval = base_interval
    last_time = data[end, time_field]
    # this while loop accounts for gaps in the underlying data
    while ==(Bool, typeof(slice))
      slice = slice_dataframe_by_time_interval(
        data, 
        time_field, 
        data[i, time_field], 
        data[i, time_field] + interval
      )
      interval += base_interval
      if <(last_time, data[i, time_field] + interval)
        return converted
      end
    end
    row = slice[begin, :]
    row[time_field] = slice[begin, time_field]
    row["open"] = slice[begin, :open]
    row["high"] = max(slice[:, :high]...)
    row["low"] = min(slice[:, :low]...)
    row["close"] = slice[end, :close]
    if ⊆(["volume"], fields)
      row["volume"] = sum(slice[:, "volume"])
    end
    push!(converted, row)
    i += nrow(slice)
    if <(nrow(data), i)
      return converted
    end
  end
end

function convert_realtime_to_ohlc(data::DataFrame, fields::Array, metrics::Dict, time_field::String, value_field::String; destination::OHLCInterval=OHLCInterval(1, "m"))
  converted = nothing
  base_interval = get_ohlc_interval(destination)
  i = 1
  while true
    slice = false
    interval = base_interval
    last_time = data[end, time_field]
    # this while loop accounts for gaps in the underlying data
    while ==(Bool, typeof(slice))
      slice = slice_dataframe_by_time_interval(
        data, 
        time_field, 
        data[i, time_field], 
        data[i, time_field] + interval
      )

      interval += base_interval
      if <(last_time, data[i, time_field] + interval)
        return converted
      end
    end

    row = Dict()
    row[value_field] = slice[end, value_field]
    row[time_field] = slice[end, time_field]
    row["graph"] = Dates.datetime2epochms(row[time_field])  # all datasets will have a graph field derived from a DateTime field
    row["open"] = slice[begin, value_field]
    row["high"] = max(slice[:, value_field]...)
    row["low"] = min(slice[:, value_field]...)
    row["close"] = slice[end, value_field]
    if ⊆(["volume"], fields)
      row["volume"] = sum(slice[:, "volume"])
    end
    for metric ∈ keys(metrics)
      row[metric] = 0.0
    end

    if ==(nothing, converted)
      converted = DataFrame(row)
    end
    push!(converted, row)

    i += nrow(slice)
    if <(nrow(data), i)
      return converted
    end
  end
end

function make_row(time_field::String, timestamp_format::String, fields::Vector, record)
  row = Dict()
  # loop over configured fields,
  # which correspond to fields in data source
  for field in fields
    if ==(true, haskey(record, field))
      # convert timestamps to DateTime
      if ==(field, time_field)
        if ==(typeof(record[field]), Int64)
          row["graph"] = Float64(record[field])
          row[field] = unix2datetime(record[field]/1000)  # TODO: surely there's a better way
        elseif ==(typeof(record[field]), DateTime)
          row[field] = record[field]
          row["graph"] = datetime2unix(record[field])
        elseif ==(typeof(record[field]), String)
          row[field] = DateTime(record[field], DateFormat(timestamp_format))
          row["graph"] = datetime2unix(row[field])
        else
          println("field type unaccounted for: typeof(record[field]) record[field]: ", string(typeof(record[field])), " ", string(record[field]))
          return false
        end
      else
        row[field] = record[field]
      end
    end
  end
  return row
end

# some metrics have configurable time periods,
# this function returns the longest metric period
# in order to ensure queries get enough data
# to calculate the metric correctly
function get_longest_metric_period(datasource::Dict)::Int64
  metric_list = ["sma"]
  longest = 0
  for op in datasource["metadata"]["etl"]
    if ==("metric", op["operation"])
      if ∈(op["name"], metric_list)
        for period in op["parameters"]["periods"]
          if <(longest, period)
            longest = period
          end
        end
      end
    end
  end
  return longest
end

# TODO: generalize to arbitrary intervals,
#       currently only days are supported.
function simple_moving_average!(p::Dict, data::DataFrame, prune::Bool=true)
  # select configured period
  for period ∈ p["periods"]
    pf = "sma_"*string(period)  # period field
    # calculate SMA
    pstart = nrow(data)
    while <=(1, pstart)
      slice = slice_dataframe_by_time_interval(
        data, 
        p["time_field"], 
        data[pstart, p["time_field"]] - Dates.Day(period), 
        data[pstart, p["time_field"]]
      )
      if !=(false, slice)
        data[pstart, pf] = sum(slice[begin:end, p["data_field"]]) / nrow(slice)
        pstart -= 1  # decrement current period start index
      else
        break
      end
    end
  end
  if prune
    for period ∈ p["periods"]
      pf = "sma_"*string(period)
      # remove invalid values
      indexes = []
      for (index, row) ∈ enumerate(eachrow(data))
        if ==(0.0, row[pf])
          append!(indexes, index)
        end
      end
      delete!(data, indexes)
    end
  end
  return data
end

# map string input to algorithm call for DataFrameRow inputs
# TODO: this can definitely be done more elegantly
function calc_metric(m::String, p::Dict, r::DataFrameRow)::Float64
  if m == "weighted_average"
    return weighted_average(p, r)
  elseif m == "bid_ask_spread"
    return bid_ask_spread(p, r)
  end
end

function weighted_average(p::Dict, r::DataFrameRow)::Float64
  t = 0.0
  for k ∈ keys(p)
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

export Socrates
export SocratesResponse
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
export get_metadata
export etl!
export slice_dataframe_by_time_interval
export convert_ohlc_interval
export convert_realtime_to_ohlc
export get_longest_metric_period

end # module
