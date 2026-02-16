with source as (
    select *
    from {{ source('raw_data', 'fhv_tripdata') }}
    where dispatching_base_num is not null
),

renamed as (
    select
        -- identifiers
        dispatching_base_num,
        affiliated_base_number,

        -- timestamps (FHV columns are typically pickup_datetime / dropoff_datetime)
        cast(pickup_datetime as timestamp) as pickup_datetime,
        cast(dropoff_datetime as timestamp) as dropoff_datetime,

        -- locations (raw is PUlocationID / DOlocationID)
        cast(pulocationid as int64) as pickup_location_id,
        cast(dolocationid as int64) as dropoff_location_id,

        -- flags
        cast(sr_flag as int64) as sr_flag
    from source
)

select * from renamed