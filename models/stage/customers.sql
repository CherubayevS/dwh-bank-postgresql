{{ config(materialized='table') }}

WITH generated_customers AS (
    SELECT 
        gs.id AS customer_id,
        'Customer ' || gs.id AS full_name,
        '770101' || LPAD(gs.id::TEXT, 6, '0') AS iin,
        '1970-01-01'::date + (random() * 12000)::int * INTERVAL '1 day' AS birth_date,
        '2010-01-01'::date + (random() * 5475)::int * INTERVAL '1 day' AS registration_date
    FROM generate_series(1, 500) AS gs(id)
)
SELECT * FROM generated_customers