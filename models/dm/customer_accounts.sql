{{ config(
    materialized='table',
    schema='dm'
) }}

SELECT 
    hc.hub_customer_hash,
    sc.full_name,
    sc.birth_date,
    sc.iin,
    sa.iban,
    sa.account_type,
    sa.open_date 
FROM {{ ref('hub_customers') }} hc -- клиент

JOIN {{ ref('link_accounts') }} la -- связь счет - клиент 
    ON hc.hub_customer_hash = la.hub_customer_hash

JOIN {{ ref('hub_accounts') }} aa -- счет
    ON aa.hub_accounts_hash = la.hub_account_hash

JOIN {{ ref('sat_customers') }} sc -- сателит клиента
    ON sc.hub_customer_hash = hc.hub_customer_hash

JOIN {{ ref('sat_accounts') }} sa -- сателит счета
    ON sa.hub_account_hash = la.hub_account_hash
