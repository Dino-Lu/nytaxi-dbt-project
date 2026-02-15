with source as (
    select *
    from {{ source('raw_data', 'yellow_tripdata') }}
    where vendorid is not null
),

renamed as (
    select
        -- identifiers
        cast(vendorid as int64) as vendor_id,
        cast(ratecodeid as int64) as rate_code_id,
        cast(pulocationid as int64) as pickup_locationid,
        cast(dolocationid as int64) as dropoff_locationid,

        -- timestamps (yellow uses tpep_*)
        cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,

        -- trip info
        store_and_fwd_flag,
        cast(passenger_count as int64) as passenger_count,
        cast(trip_distance as numeric) as trip_distance,

        -- yellow usually has no trip_type; keep it nullable for union compatibility
        cast(1 as int64) as trip_type,  -- Yellow only does street-hail

        -- payment info
        cast(fare_amount as numeric) as fare_amount,
        cast(extra as numeric) as extra,
        cast(mta_tax as numeric) as mta_tax,
        cast(tip_amount as numeric) as tip_amount,
        cast(tolls_amount as numeric) as tolls_amount,
        cast(0 as numeric) as ehail_fee,
        cast(improvement_surcharge as numeric) as improvement_surcharge,
        cast(total_amount as numeric) as total_amount,
        cast(payment_type as int64) as payment_type

    from source
)

select *
from renamed