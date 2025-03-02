{{ config(materialized='table') }}

WITH generated_accounts AS (
    SELECT 
        gs.id AS account_id,
        (random() * 500)::INT + 1 AS customer_id,
        'KZ' || LPAD((random() * 999999)::TEXT, 18, '0') AS iban,
        CASE WHEN random() > 0.5 THEN 'Сберегательный' ELSE 'Текущий' END AS account_type,
        '2015-01-01'::date + (random() * 3650)::int * INTERVAL '1 day' AS open_date
    FROM generate_series(1, 700) AS gs(id)
)
SELECT * FROM generated_accounts