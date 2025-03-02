{{ config(materialized='table') }}

WITH generated_transactions AS (
    SELECT 
        gs.id AS transaction_id,
        (random() * 700)::INT + 1 AS account_id,
        (random() * 100000)::NUMERIC(12,2) AS amount,
        CASE WHEN random() > 0.5 THEN 'Пополнение' ELSE 'Списание' END AS transaction_type,
        '2020-01-01'::date + (random() * 1825)::int * INTERVAL '1 day' AS transaction_date
    FROM generate_series(1, 5000) AS gs(id)
)
SELECT * FROM generated_transactions