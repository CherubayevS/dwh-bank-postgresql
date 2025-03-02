{{ config(
    materialized='incremental',
    schema='dds',
    unique_key='link_key',
    incremental_strategy='merge'
) }}

WITH source_data AS (
    SELECT 
        md5(customer_id::text) AS hub_customer_hash,
        md5(iban::text) AS hub_account_hash,
        md5(customer_id::text || iban::text) AS link_key,
        NOW() AS load_date
    FROM stage.accounts
)

-- Если это полный запуск (dbt --full-refresh), создаем таблицу с нуля
{% if is_incremental() %}

SELECT * FROM source_data
WHERE NOT EXISTS (
    SELECT 1 FROM dds.link_accounts t
    WHERE t.link_key = source_data.link_key
);

{% else %}

SELECT * FROM source_data

{% endif %}