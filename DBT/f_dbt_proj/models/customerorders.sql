-- Defined/Materialized O/P Config for this model = Table 
{{config(materialized='table')}}

-- Mentioned Data Transformation Logic
WITH CUSTOMERORDERS AS (
    SELECT C.CUSTOMERID, CONCAT(C.FIRSTNAME, ' ', C.LASTNAME) AS CUSTOMERNAME, COUNT(O.ORDERID) AS NO_OF_ORDERS
    FROM L1_LANDING.CUSTOMERS C
    LEFT JOIN L1_LANDING.ORDERS O
    ON C.CUSTOMERID = O.CUSTOMERID
    GROUP BY C.CUSTOMERID, CUSTOMERNAME
    ORDER BY NO_OF_ORDERS DESC
)

SELECT CUSTOMERID, CUSTOMERNAME, NO_OF_ORDERS 
FROM CUSTOMERORDERS