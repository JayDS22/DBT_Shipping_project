{% macro to_celsius(fahrenheit_column, decimal_places)%}
 ROUND(({{fahrenheit_column}} - 32) * 5 / 9, {{decimal_places}})
{% endmacro %}

{% macro generate_profit_model(table_name)%}
SELECT SALES_DATE, 
    SUM(QUANTITY_SOLD * UNIT_SELL_PRICE) AS Total_Revenue,
    SUM(QUANTITY_SOLD * UNIT_PURCHASE_COST) AS Total_Cost,
    SUM(QUANTITY_SOLD * UNIT_SELL_PRICE - QUANTITY_SOLD * UNIT_PURCHASE_COST) AS Total_Profit
FROM {{source('training', table_name)}}
GROUP BY SALES_DATE
{% endmacro %}