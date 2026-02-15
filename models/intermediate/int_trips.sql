with trips as (
    select *
    from {{ ref('int_trips_unioned') }}
),

payment_types as (
    select * from {{ ref('payment_type_lookup') }}
),

-- 1) Create a stable, deterministic trip_id
-- Use columns that together describe a trip at the grain "one trip"
with_trip_id as (
    select
        to_hex(md5(concat(
            coalesce(cast(service_type as string), ''), '|',
            coalesce(cast(vendor_id as string), ''), '|',
            coalesce(cast(pickup_datetime as string), ''), '|',
            coalesce(cast(dropoff_datetime as string), ''), '|',
            coalesce(cast(pickup_locationid as string), ''), '|',
            coalesce(cast(dropoff_locationid as string), ''), '|',
            coalesce(cast(passenger_count as string), ''), '|',
            coalesce(cast(trip_distance as string), ''), '|',
            coalesce(cast(total_amount as string), '')
        ))) as trip_id,
        *
    from trips
),

-- 2) Deduplicate: keep exactly one row per trip_id
-- Pick the "best" record deterministically.
deduped as (
    select *
    from with_trip_id
    qualify row_number() over (
        partition by trip_id
        order by
          -- prefer records with non-null dropoff, then latest dropoff
          (dropoff_datetime is null) asc,
          dropoff_datetime desc,
          pickup_datetime desc
    ) = 1
),

-- 3) Enrich payment type from seed
enriched as (
    select
        d.*,
        p.description as payment_type_description
    from deduped d
    left join payment_types p
      on cast(d.payment_type as int64) = cast(p.payment_type as int64)
)

select * from enriched