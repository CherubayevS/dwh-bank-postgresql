{{ config(
    materialized='incremental',
    schema='dds',
    unique_key='record_hash'
) }}

-- Проверяем, существует ли таблица. Если нет — создаем её.
{% if is_incremental() %}
  {% set exists_query %}
      SELECT to_regclass('{{ this }}') IS NOT NULL AS table_exists
  {% endset %}

  {% set table_exists = run_query(exists_query).columns[0].values()[0] %}

  {% if not table_exists %}
    CREATE TABLE {{ this }} (
        hub_account_hash TEXT NOT NULL,
        account_id INT NOT NULL,
        customer_id INT NOT NULL,
        iban TEXT,
        account_type TEXT,
        open_date TIMESTAMP,
        record_hash TEXT PRIMARY KEY,
        load_time TIMESTAMP NOT NULL,
        valid_from TIMESTAMP NOT NULL,
        valid_to TIMESTAMP,
        is_active BOOLEAN NOT NULL DEFAULT TRUE
    );
  {% endif %}
{% endif %}

WITH source_data AS (
    SELECT 
        md5(iban::text) AS hub_account_hash,
        account_id,
        customer_id,
        iban,
        account_type,
        open_date,
--        md5(CAST(account_id AS TEXT) || CAST(customer_id AS TEXT)) AS record_hash,
        md5(iban::text) AS record_hash,
        NOW() AS load_time,
        NOW() AS valid_from
    FROM stage.accounts
),

latest_records AS (
    SELECT
        hub_account_hash,
        record_hash,
        MAX(valid_from) AS max_valid_from
    FROM {{ this }}
    WHERE valid_to IS NULL
    GROUP BY hub_account_hash, record_hash
),

existing_records AS (
    SELECT
        sat.hub_account_hash,
        sat.account_id,
        sat.customer_id,
        sat.iban,
        sat.account_type,
        sat.open_date,
        sat.record_hash,
        sat.load_time,
        sat.valid_from,
        sat.valid_to,
        sat.is_active
    FROM {{ this }} sat
    JOIN latest_records lr
    ON sat.hub_account_hash = lr.hub_account_hash
    AND sat.record_hash = lr.record_hash
    AND sat.valid_from = lr.max_valid_from
)

SELECT 
    sd.hub_account_hash,
    sd.account_id,
    sd.customer_id,
    sd.iban,
    sd.account_type,
    sd.open_date,
    sd.record_hash,
    sd.load_time,
    sd.valid_from,
    NULL::TIMESTAMP AS valid_to,
    TRUE AS is_active
FROM source_data sd
LEFT JOIN existing_records er
ON sd.hub_account_hash = er.hub_account_hash
AND sd.record_hash = er.record_hash
WHERE er.record_hash IS NULL

{% if is_incremental() %}
UNION ALL

SELECT 
    er.hub_account_hash,
    er.account_id,
    er.customer_id,
    er.iban,
    er.account_type,
    er.open_date,
    er.record_hash,
    er.load_time,
    er.valid_from,
    NOW() AS valid_to,
    FALSE AS is_active
FROM existing_records er
JOIN source_data sd
ON er.hub_account_hash = sd.hub_account_hash
AND er.record_hash <> sd.record_hash
WHERE er.valid_to IS NULL
{% endif %}
