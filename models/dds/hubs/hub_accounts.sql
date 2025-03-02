{{ config(
    materialized='incremental',
    schema='dds',
    unique_key='hub_accounts_hash'
) }}

WITH source_data AS (
    SELECT DISTINCT 
        md5(iban::text) AS hub_accounts_hash,
        iban,
        NOW() AS load_time
    FROM stage.accounts
)

-- Если это полный запуск (dbt --full-refresh), создаем таблицу с нуля
{% if is_incremental() %}

SELECT * FROM source_data
WHERE NOT EXISTS (
    SELECT 1 FROM dds.hub_accounts t
    WHERE t.hub_accounts_hash = source_data.hub_accounts_hash
)

{% else %}

SELECT * FROM source_data

{% endif %}