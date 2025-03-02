{{ config(materialized='table') }}

WITH products AS (
    SELECT * FROM (VALUES
        (1, 'Ипотечный кредит', 'Кредит'),
        (2, 'Потребительский кредит', 'Кредит'),
        (3, 'Автокредит', 'Кредит'),
        (4, 'Кредитная карта', 'Кредит'),
        (5, 'Депозит срочный', 'Депозит'),
        (6, 'Депозит накопительный', 'Депозит'),
        (7, 'Текущий счет', 'Счет')
    ) AS bp(product_id, product_name, product_type)
)
SELECT * FROM products