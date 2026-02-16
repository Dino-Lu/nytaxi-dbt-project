# NYC Taxi Analytics Engineering Project (dbt + BigQuery)

## Overview

This project transforms NYC Taxi trip data (2019–2020) into an analytics-ready warehouse using dbt and BigQuery.

This project demonstrates:

- Standardization of raw taxi trip data
- Layered transformation architecture (staging → intermediate → marts)
- Star schema implementation
- Incremental fact modeling
- Data quality testing and contract enforcement
- Aggregated reporting model design

This project was developed as part of the DataTalksClub Data Engineering Zoomcamp – Module 4 (Analytics Engineering with dbt).

---

## Data Architecture

Raw Data (GCS)  
→ BigQuery landing tables (`nytaxi` dataset)  
→ dbt transformations  
→ Staging → Intermediate → Marts  
→ Reporting models  

Two environments were used:

- `dbt_jlu` — development dataset  
- `analytics_prod` — production dataset (used for homework queries)

Production builds were executed through a deployment job in dbt Cloud.

---

## Project Structure

```
models/
├── staging/
│   ├── stg_green_tripdata.sql
│   ├── stg_yellow_tripdata.sql
│   ├── stg_fhv_tripdata.sql
│   └── sources.yml
│
├── intermediate/
│   ├── int_trips_unioned.sql
│   └── int_trips.sql
│
└── marts/
    ├── dim_zones.sql
    ├── dim_vendors.sql
    ├── fct_trips.sql
    └── reporting/
        └── fct_monthly_zone_revenue.sql
```

---

## Data Model

### Fact Table

**fct_trips**

- One row per taxi trip (Green + Yellow combined)
- Incremental model using MERGE strategy
- Surrogate primary key: `trip_id`
- Deduplicated at the intermediate layer
- Enriched with:
  - Zone details
  - Vendor information
  - Payment type descriptions
  - Trip duration

---

### Dimension Tables

- `dim_zones` — Taxi zone lookup (seed-based)
- `dim_vendors` — Vendor mapping (macro-based)
- `payment_type_lookup` — Payment type descriptions (seed-based)

---

### Reporting Model

**fct_monthly_zone_revenue**

Aggregated model grouped by:

- Pickup zone
- Revenue month
- Service type

Metrics include:

- Monthly total revenue
- Fare breakdown components
- Monthly trip count
- Average passenger count
- Average trip distance

---

## Key Implementation Details

- Incremental fact model with `unique_key = trip_id`
- Deduplication handled in `int_trips`
- Surrogate key generation
- Seeds for dimensional enrichment
- Macros for:
  - Safe casting
  - Vendor mapping
  - Trip duration calculation
- Generic tests:
  - `unique`
  - `not_null`
  - `relationships`
  - `accepted_values`
- Contract enforcement in marts layer
- Partitioned tables in BigQuery
- Separate development and production targets

---

## Data Quality

Implemented tests include:

- Unique and not_null tests on primary keys
- Relationship tests between fact and dimensions
- Accepted values validation for service_type
- Source freshness checks
- Contract enforcement on fact tables

All tests pass successfully in the production environment.

---

## How to Run

### Using dbt Cloud

- Development: Use the IDE and run `dbt run` or `dbt build`
- Production: Trigger the deployment job configured for the `analytics_prod` environment
Note: This project was developed primarily using dbt Cloud.

### Using dbt Core (CLI)

For dbt Core users (local execution):

```bash
dbt deps
dbt run
dbt test
```

To build production models:

```bash
dbt build --target prod
```

Ensure your `profiles.yml` is configured with the appropriate targets.

---

## Technologies Used

- dbt
- Google BigQuery
- Google Cloud Storage
- Docker
- Python
- GitHub

---

## What This Project Demonstrates

- Layered analytics engineering architecture
- Star schema design
- Incremental modeling at scale
- Data quality testing best practices
- Production vs development workflow management
- Business-oriented reporting model design

---

## Module 4 Homework Results

All models were built using dbt and validated with `dbt build`.  
The production dataset (`analytics_prod`) was used for all final queries.

---

### Question 1 — dbt Lineage and Execution

**If running:**

```bash
dbt run --select int_trips_unioned
```

**Answer:**

`stg_green_tripdata`, `stg_yellow_tripdata`, and `int_trips_unioned`

**Explanation:**

dbt builds the selected model and its upstream dependencies.  
Downstream models are not executed unless explicitly selected.

---

### Question 2 — dbt Tests

If a new value `6` appears in `payment_type` while an `accepted_values` test allows only `[1,2,3,4,5]`:

**Answer:**

dbt will fail the test and return a non-zero exit code.

**Explanation:**

Generic tests validate model output against declared expectations.  
Any new unexpected value causes test failure.

---

### Question 3 — Count of Records in `fct_monthly_zone_revenue`

**Query executed:**

```sql
select count(*)
from analytics_prod.fct_monthly_zone_revenue;
```

**Answer:**

12,184

---

### Question 4 — Best Performing Zone (Green Taxis, 2020)

**Query logic:**
- Filter: `service_type = 'Green'`
- Filter: `revenue_month` in 2020
- Order by `revenue_monthly_total_amount` DESC

**Answer:**

East Harlem North

---

### Question 5 — Green Taxi Trips (October 2019)

**Query executed:**

```sql
select total_monthly_trips
from analytics_prod.fct_monthly_zone_revenue
where service_type = 'Green'
  and revenue_month = '2019-10-01';
```

**Answer:**

384,624

---

### Question 6 — FHV Staging Model

A staging model `stg_fhv_tripdata` was created with:

- Filter: `dispatching_base_num IS NOT NULL`
- Renamed fields to match project naming conventions
- Loaded from CSV source into BigQuery

**Query executed:**

```sql
select count(*)
from analytics_prod.stg_fhv_tripdata;
```

**Answer:**

43,244,693

---