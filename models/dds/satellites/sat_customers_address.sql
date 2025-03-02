{{ config(
    materialized='incremental',
    schema='dds',
    unique_key='record_hash'
) }}

WITH source_data AS (
    SELECT 
        md5(customer_id::text) AS hub_customer_hash,
        city,
        district,
        street,
        house_number,
        apartment_number,
        md5(city || district || street || house_number || COALESCE(apartment_number, '')) AS record_hash, 
        NOW() AS load_time,
        NOW() AS valid_from
    FROM stage.customers_address
),

latest_records AS (
    SELECT
        hub_customer_hash,
        record_hash,
        MAX(valid_from) AS max_valid_from
    FROM {{ this }}
    WHERE valid_to IS NULL -- Берем только актуальные записи
    GROUP BY hub_customer_hash, record_hash
),

existing_records AS (
    SELECT
        sat.hub_customer_hash,
        sat.city,
        sat.district,
        sat.street,
        sat.house_number,
        sat.apartment_number,
        sat.record_hash,
        sat.load_time,
        sat.valid_from,
        sat.valid_to,
        sat.is_active
    FROM {{ this }} sat
    JOIN latest_records lr
    ON sat.hub_customer_hash = lr.hub_customer_hash
    AND sat.record_hash = lr.record_hash
    AND sat.valid_from = lr.max_valid_from
)

-- Добавляем новые записи, если изменился record_hash
SELECT 
    sd.hub_customer_hash,
    sd.city,
    sd.district,
    sd.street,
    sd.house_number,
    sd.apartment_number,
    sd.record_hash,
    sd.load_time,
    sd.valid_from,
    NULL::TIMESTAMP AS valid_to,  -- Открытая запись
    TRUE AS is_active
FROM source_data sd
LEFT JOIN existing_records er
ON sd.hub_customer_hash = er.hub_customer_hash
AND sd.record_hash = er.record_hash
WHERE er.record_hash IS NULL

{% if is_incremental() %}
UNION ALL

-- Закрываем старые записи (устанавливаем valid_to, is_active = FALSE)
SELECT 
    er.hub_customer_hash,
    er.city,
    er.district,
    er.street,
    er.house_number,
    er.apartment_number,
    er.record_hash,
    er.load_time,
    er.valid_from,
    NOW() AS valid_to,  -- Закрываем запись
    FALSE AS is_active
FROM existing_records er
JOIN source_data sd
ON er.hub_customer_hash = sd.hub_customer_hash
AND er.record_hash <> sd.record_hash
WHERE er.valid_to IS NULL
{% endif %}
