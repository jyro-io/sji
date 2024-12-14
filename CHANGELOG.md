### 4.17.0

* add EMA metric

### 4.16.0

* remove model management functions

### 4.15.0

* remove threading option in etl since the underlying functions are optimized
* fix metrics in convert_to_ohlc

### 4.14.2

* optimize convert_to_ohlc

### 4.14.1

* optimize convert_ohlc_interval

### 4.14.0

* get_predictive_model -> get_model

### 4.13.0

* add threading flag option to etl!(),
  since this seems to cause problems with nested tasks elsewhere

### 4.12.1

* fix precompilation problem...
* add register.sh convenience script

### 4.12.0

* add GreatValueMath.jl to this package to make it easier to deprecate

### 4.11.0

* add etl! method that excludes metrics calculations

### 4.10.0

* update get_metadata interface to make scraper_definition an optional keyword parameter

### 4.9.0

* etl!() now handles pre-ETL interval conversion in all cases,
  this greatly decreases etl!() processing time
* adjust etl!() method signature
* interval parameter is now a first-class citizen in datasource definitions

### 4.8.0

* add threads to SMA calculation in etl!()
* add OHLC interval parameter to etl!()
* various refactors

### 4.7.10

* add threads to etl!()
* switch helper functions from DataFrame -> AbstractDataFrame

### 4.7.9

* bugfix: add timezoning

### 4.7.8

* bugfix: fix graph field calculation

### 4.7.7

* add ZonedDateTime call

### 4.7.6

* add TimeZones

### 4.7.5

* bugfix: data field extraction in get_metadata

### 4.7.4

* add missing column during metric calculation

### 4.7.3

* bump version for private registry

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
