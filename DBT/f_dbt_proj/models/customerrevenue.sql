SELECT 
    OS.CustomerID,
    C.CustomerName,
    SUM(OS.OrderCount) AS OrderCount,
    SUM(OS.Revenue) AS Revenue
FROM 
    {{ref('orders_fact')}} AS OS
JOIN 
    {{ref('customers_stg')}} AS C ON OS.CustomerID = C.CustomerID
GROUP BY
    OS.CustomerID,
    C.CustomerName