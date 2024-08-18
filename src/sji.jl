__precompile__(true)
module sji

# this is temporary while I deprecate usage of these functions
include("GreatValueMath.jl")
using .GreatValueMath
export min_max_feature_scale_normalization
export normalize
export theil_sen
export linear_least_squares

using .GC
using Parameters
using JSON
using HTTP
using Dates
using Mongoc
using DataFrames
using TimeZones
using Base.Threads

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

struct OHLCInterval
  interval::Int64
  unit::String
end

function get_model(c::Socrates, name::String, datasource::String, type::String)::SocratesResponse
  #=
  Get a model

  positional arguments:
    c <Socrates> client type
    name <String> model name
    datasource <String> datasource name
    type <String> model type ["mlp"]
  =#

  if ==("mlp", type)
    url = c.protocol*"://"*c.host*"/archimedes/mlp"
  end
  params = Dict{String,String}(
    "operation"=>"get",
    "datasource"=>datasource,
    "name"=>name
  )
  r = HTTP.post(
    url,
    c.headers,
    JSON.json(params),
    require_ssl_verification = c.verify,
  )
  response = String(r.body)
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

function get_metadata(datasource::Dict; scraper_definition::Dict=Dict())::SocratesResponse
  metrics = Dict()
  fields = []

  if haskey(scraper_definition, "rules")
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
  end

  # scan datasource ETL pipeline for metrics
  datasource["metadata"]["etl"]::Array
  for op in datasource["metadata"]["etl"]
    op::Dict
    if ==(op["operation"], "metric")
      if ==(op["name"], "weighted_average")
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
    elseif ==(op["operation"], "ohlc") || ==(op["name"], "sma")
      push!(fields, op["parameters"]["data_field"])
    end
  end
  # split SMA into constituent metrics according to configured periods
  if haskey(metrics, "sma")
    for op in datasource["metadata"]["etl"]
      if ==(op["operation"], "metric")
        if ==(op["name"], "sma")
          for period in op["parameters"]["periods"]
            metrics["sma_"*string(period)] = op["parameters"]
          end
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

function etl!(
  data::DataFrame,
  datasource::Dict,
  fields::Array,
  metrics::Dict;
  interval::OHLCInterval=OHLCInterval(1, "m"),
  prune::Bool=true,
  threads::Bool=true,
)
  if ==(haskey(datasource["metadata"], "etl"), true)

    # in non-realtime cases, check to see if the given interval differs from the datasource interval;
    # if so, convert to the given interval before proceeding.
    # realtime is excluded because it will get handled in the "ohlc" operation below.
    if !=(datasource["interval"], "realtime") && !=(datasource["interval"], [interval.interval, interval.unit])
      data = convert_ohlc_interval(
        data,
        datasource["timestamp_field"],
        fields,
        interval,
      )
    end

    for op in datasource["metadata"]["etl"]
      # convert realtime data to OHLC
      if ==(op["operation"], "ohlc")
        if threads
          # calculate chunk intervals
          chunks = Iterators.partition(data, floor(Int, nrow(data) / Threads.nthreads()))
          # convert using interval per thread
          tasks = map(chunks) do chunk
            Threads.@spawn convert_to_ohlc(
              chunk,
              op["parameters"]["time_field"],
              op["parameters"]["data_field"],
              metrics,
              interval
            )
          end
          data = fetch.(tasks)
          # reduce Vector{DataFrame} to DataFrame
          data = reduce(vcat, filter(x -> x !== nothing, data))
          # make sure async processing didn't return incorrect ordering
          sort!(data, datasource["timestamp_field"])
        else
          data = convert_to_ohlc(
            data,
            op["parameters"]["time_field"],
            op["parameters"]["data_field"],
            metrics,
            interval
          )
        end
      # calculate metrics
      elseif ==(op["operation"], "metric")
        if ==(op["name"], "sma")
          if threads
            # convert using period per thread
            tasks = map(op["parameters"]["periods"]) do period
              Threads.@spawn simple_moving_average!(
                data,
                period,
                op["parameters"]["data_field"],
                op["parameters"]["time_field"],
              )
            end
            # only columns are returned
            data = fetch.(tasks)
            # reduce Vector{DataFrame} to DataFrame
            data = reduce(vcat, filter(x -> x !== nothing, data))
            # make sure async processing didn't return incorrect ordering
            sort!(data, datasource["timestamp_field"])
          else
            for period in op["parameters"]["periods"]
              data = simple_moving_average!(
                data,
                period,
                op["parameters"]["data_field"],
                op["parameters"]["time_field"],
              )
            end
          end

          if prune
            periods = deepcopy(op["parameters"]["periods"])
            # remove columns where all values are zero
            indexes = []
            for (i, period) ∈ enumerate(periods)
              remove = true
              pf = "sma_"*string(period)  # period field
              for row ∈ eachrow(data)
                if !=(0.0, row[pf])
                  remove = false
                  break
                end
              end
              if remove
                select!(data, Not(pf))
                append!(indexes, i)
              end
            end
            deleteat!(periods, indexes)
            # remove rows where any value is zero
            indexes = []
            for (i, row) ∈ enumerate(eachrow(data))
              for period ∈ periods
                pf = "sma_"*string(period)  # period field
                if ==(0.0, row[pf])
                  append!(indexes, i)
                  break
                end
              end
            end
            deleteat!(data, indexes)
          end
        else
          # check for metric column and create
          if !hasproperty(data, op["name"])
            data[!, op["name"]] = fill(0.0, nrow(data))
          end
          for (i, d) in enumerate(eachrow(data))
            data[i, op["name"]] = calc_metric(op["name"], op["parameters"], d)
          end
        end
      end
    end
  end
  GC.gc()
  return data
end

function etl!(
  data::DataFrame,
  datasource::Dict,
  fields::Array;
  interval::OHLCInterval=OHLCInterval(1, "m"),
  threads::Bool=true,
)
  if ==(haskey(datasource["metadata"], "etl"), true)

    # in non-realtime cases, check to see if the given interval differs from the datasource interval;
    # if so, convert to the given interval before proceeding.
    # realtime is excluded because it will get handled in the "ohlc" operation below.
    if !=(datasource["interval"], "realtime") && !=(datasource["interval"], [interval.interval, interval.unit])
      data = convert_ohlc_interval(
        data,
        datasource["timestamp_field"],
        fields,
        interval,
      )
    end

    for op in datasource["metadata"]["etl"]
      # convert realtime data to OHLC
      if ==(op["operation"], "ohlc")
        if threads
          # calculate chunk intervals
          chunks = Iterators.partition(data, floor(Int, nrow(data) / Threads.nthreads()))
          # convert using interval per thread
          tasks = map(chunks) do chunk
            Threads.@spawn convert_to_ohlc(
              chunk,
              op["parameters"]["time_field"],
              op["parameters"]["data_field"],
              Dict(),  # empty dict since this method excludes metrics
              interval
            )
          end
          data = fetch.(tasks)
          # reduce Vector{DataFrame} to DataFrame
          data = reduce(vcat, filter(x -> x !== nothing, data))
          # make sure async processing didn't return incorrect ordering
          sort!(data, datasource["timestamp_field"])
        else
          data = convert_to_ohlc(
            data,
            op["parameters"]["time_field"],
            op["parameters"]["data_field"],
            Dict(),  # empty dict since this method excludes metrics
            interval
          )
        end
      end
    end
  end
  GC.gc()
  return data
end

function slice_dataframe_by_time_interval(data::AbstractDataFrame, field::String, start::DateTime, stop::DateTime)
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

function convert_ohlc_interval(
  data::AbstractDataFrame,
  time_field::String,
  fields::Array,
  destination::OHLCInterval
)
  time_field = Symbol(time_field)
  interval_duration = get_ohlc_interval(destination)
  data.timegroup = floor.(data[:, time_field], interval_duration)
  if ⊆(["volume"], fields)
    grouped = combine(groupby(data, :timegroup),
      :open => first => :open,
      :high => maximum => :high,
      :low => minimum => :low,
      :close => last => :close,
      :volume => sum => :volume,
    )
  else
    grouped = combine(groupby(data, :timegroup),
      :open => first => :open,
      :high => maximum => :high,
      :low => minimum => :low,
      :close => last => :close,
    )
  end

  sort!(grouped, :timegroup)
  rename!(grouped, :timegroup => time_field)

  return grouped
end

function convert_to_ohlc(
  data::AbstractDataFrame,
  time_field::String,
  data_field::String,
  metrics::Dict,
  destination::OHLCInterval=OHLCInterval(1, "m")
)
  time_field = Symbol(time_field)
  data_field = Symbol(data_field)
  interval_duration = get_ohlc_interval(destination)
  data.timegroup = floor.(data[:, time_field], interval_duration)
  if ⊆(["volume"], fields)
    grouped = combine(groupby(data, :timegroup),
      data_field => first => :open,
      data_field => maximum => :high,
      data_field => minimum => :low,
      data_field => last => :close,
      :volume => sum => :volume,
    )
  else
    grouped = combine(groupby(data, :timegroup),
      data_field => first => :open,
      data_field => maximum => :high,
      data_field => minimum => :low,
      data_field => last => :close,
    )
  end

  sort!(grouped, :timegroup)
  rename!(grouped, :timegroup => time_field)

  return grouped
end

function make_row(time_field::String, timestamp_format::String, fields::Vector, record)
  #=
  Create a row formatted in a standardized way for Socrates applications

  positional arguments:
    time_field <String> timestamp field name
    timestamp_format <String> format string for parsing
    fields <Vector> vector of datasource field names
  =#

  row = Dict()
  # loop over configured fields,
  # which correspond to fields in data source
  for field in fields
    if haskey(record, field)
      # convert timestamps to DateTime
      if ==(field, time_field)
        if ==(typeof(record[field]), Int64)
          row["graph"] = Float64(record[field])
          # TODO: surely there's a better way than /1000
          row[field] = unix2datetime(record[field]/1000)
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

function push_row!(dataframe, row)
  for field in keys(row)
    if !hasproperty(dataframe, field)
      dataframe[!, field] = fill(0.0, nrow(dataframe))
    end
  end
  push!(dataframe, row; promote=true)
  return dataframe
end

function add_fields!(row::Dict, metrics::Dict)
  for metric ∈ keys(metrics)
    if !(haskey(row, metric))
      row[metric] = 0.0
    end
  end
  for field ∈ ["open", "high", "low", "close"]
    if !(haskey(row, field))
      row[field] = 0.0
    end
  end
  return row
end

function add_fields!(dataframe::AbstractDataFrame, metrics::Dict)
  for metric ∈ keys(metrics)
    if !hasproperty(dataframe, metric)
      dataframe[!, metric] = fill(0.0, nrow(dataframe))
    end
  end
  for field ∈ ["open", "high", "low", "close"]
    if !hasproperty(dataframe, field)
      dataframe[!, field] = fill(0.0, nrow(dataframe))
    end
  end
  return dataframe
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
function simple_moving_average!(
  data::AbstractDataFrame,
  period::Int64,
  data_field::String,
  time_field::String,
)
  pf = "sma_"*string(period)  # period field
  # check for metric in dataframe and create
  if !hasproperty(data, pf)
    data[!, pf] = fill(0.0, nrow(data))
  end
  # calculate SMA
  pstart = nrow(data)
  while <=(1, pstart)
    slice = slice_dataframe_by_time_interval(
      data,
      time_field,
      data[pstart, time_field] - Dates.Day(period),
      data[pstart, time_field]
    )
    if !=(false, slice)
      data[pstart, pf] = sum(slice[begin:end, data_field]) / nrow(slice)
      pstart -= 1  # decrement current period start index
    else
      break
    end
  end
  return data
end

# map string input to algorithm call for DataFrameRow inputs
# TODO: this can probably be done more elegantly
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
export get_model

end # module
