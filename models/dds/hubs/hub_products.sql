{{ config(
    materialized='incremental',
    schema='dds',
    unique_key='hub_product_id_hash'
) }}

WITH source_data AS (
    SELECT DISTINCT 
        md5(product_id::text) AS hub_product_id_hash,
        product_id,
        product_name,
        product_type,
        NOW() AS load_time
    FROM stage.bank_products
)

-- Если это полный запуск (dbt --full-refresh), создаем таблицу с нуля
{% if is_incremental() %}

SELECT * FROM source_data
WHERE NOT EXISTS (
    SELECT 1 FROM dds.hub_products t
    WHERE t.hub_product_id_hash = source_data.hub_product_id_hash
)

{% else %}

SELECT * FROM source_data

{% endif %}