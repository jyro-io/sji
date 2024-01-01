### 4.7.2

* convert_realtime_to_ohlc -> convert_to_ohlc
* generalize convert_to_ohlc slightly so that it fits into ETL workflow
  instead of standing alone
* remove pull_fields construct in favor of automatic field collection

### 4.7.1

* bugfix: problem in convert_realtime_to_ohlc where the input dataframe
          does not match what output dataframe should be.

### 4.7.0

* refactor: add mutation notation to functions

### 4.6.0

* feature: add get_predictive_model
* feature: add update_predictive_model

### 4.5.0

* refactor: get_ohlc_interval_method -> get_ohlc_interval

### 4.4.2

* refactor: update simple_moving_average to use slice_dataframe_by_time_interval
* refactor: move metrics.jl into sji.jl

### 4.4.1

* feature: add get_longest_metric_period

### 4.4.0

* mbedtls -> openssl

### 4.3.0

* added convert_realtime_to_ohlc method
* refactor convert_ohlc_interval

### 4.2.2

* bugfix: return value interface for simple_moving_average

### 4.2.1

* add check for option field in datasource definition

### 4.2.0

* fixing slice_dataframe_by_time_interval

### 4.1.0

* get_mongo_records include parameter is now optional

### 4.0.1

* refactor get_slice_by_time_interval with guardrails

### 4.0.0

* feature: remove explicit exlcude from get_mongo_records in favor of implicit via `field ∉ include`
* add option to delete records that don't contain SMA data after calculation

### 3.13.0

* feature: add candle interval conversion functions
* minor refactors

### 3.12.1

* add failure condition in SMA function
* bugfix: SMA metric not calculating correctly

### 3.12.0

* feature: add SMA metric
* remove Manifest.toml file

### 3.11.0

* feature: add get_slice_by_time_interval

### 3.10.3

* feature: add debug flag to socrates object

### 3.10.2

* housekeeping: upgrade package manifest; hoping MbedTLS 1.1.6 -> 1.1.7 fixes ssl renegotiation problem

### 3.10.1

* bugfix: support connecting to native and replicated mongo datasources

### 3.10.0

* feature: connect to mongo replicaset

### 3.9.0

* feature: adding filter to get_mongo_records

### 3.8.0

* julia 1.7 -> 1.8.2
* add ssl renegotiation: https://github.com/JuliaWeb/HTTP.jl/issues/342
* package manifest updates

### 3.7.1

* fix params Dict type restriction in get_raw_data

### 3.7.0

* remove type restrictions on time parameters in get_raw_data

### 3.6.1

* fix get_raw_data

### 3.6.0

* fix exports

### 3.5.0

* make exports make sense

### 3.4.0

* generalizing ETL

### 3.3.0

* adding get_metadata function to enable generalized ETL

### 3.2.0

* adding kafka logic to get_raw_data

### 3.1.0

* adding get_mongo_records()
* adding connect_to_datasource()

### 3.0.0

* adding update_config()
* removing
* fixing indentation

### 2.1.0

* reverting 2.0.0, socrates API already does that

### 2.0.0

* get_config(): automatically return body of config, instead of returning full JSON

### 1.1.0

* adding get_config()
* adding export for get_unreviewed_index_records()

### 1.0.0

* updating Socrates interface
* updating get_unreviewed_index_records interface
* fixing logging

### 0.8.1

* updating get_unreviewed_index_records() to correct Socrates endpoint

### 0.8.0

* adding get_unreviewed_index_records()
* adding CHANGELOG.md
