{{ config(
    materialized='incremental',
    schema='dds',
    unique_key='hub_customer_hash'
) }}

WITH source_data AS (
    SELECT DISTINCT 
        md5(customer_id::text) AS hub_customer_hash,
        customer_id,
        NOW() AS load_time
    FROM stage.customers
)

-- Если это полный запуск (dbt --full-refresh), создаем таблицу с нуля
{% if is_incremental() %}

SELECT * FROM source_data
WHERE NOT EXISTS (
    SELECT 1 FROM dds.hub_customers t
    WHERE t.hub_customer_hash = source_data.hub_customer_hash
)

{% else %}

SELECT * FROM source_data

{% endif %}