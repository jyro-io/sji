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
