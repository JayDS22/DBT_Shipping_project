--Make this Model - To incrementally load data
{{ config(materialized='incremental', unique_key='OrderID') }}

SELECT
    OrderID,
    OrderDate,
    CustomerID,
    EmployeeID,
    StoreID,
    Status As StatusCD,
    CASE 
        WHEN Status='01' THEN 'In Progress'
        WHEN Status='02' THEN 'Completed'
        WHEN Status='03' THEN 'Cancelled'
        ELSE 'Unknown'
    END AS StatusDesc,
    CASE 
        WHEN StoreID < 5 THEN 'Online'
        ELSE 'In-Store'
    END AS ORDER_CHANNEL,
    updated_at,
    current_timestamp AS dbt_updated_at
FROM
    {{source('landing', 'ordr')}}


{% if is_incremental() %}
    WHERE Updated_at >= (SELECT MAX(dbt_updated_at) FROM {{ this }})
{% endif %}