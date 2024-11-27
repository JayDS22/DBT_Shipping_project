{% snapshot customers_history %}

{{
    config(
        target_schema='l3_consumption',
        unique_key='CUSTOMERID',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}

SELECT * FROM {{ source('landing', 'cust')}}

{% endsnapshot %}

-- Using Above Config -> Creates Snapshot Table (initially) 
-- Overtime (Adds New Records) -> (DBT_SCD_ID, DBT_UPDATED_AT, DBT_VALID_FROM, DBT_VALID_TO)