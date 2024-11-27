{% docs StatusCD %}

One of the following values:

| Code | Status          | Description                                      |
|------|-----------------|--------------------------------------------------|
| 01   | Shipping        | The order is currently being prepared or shipped.|
| 02   | Delivered       | The order has been successfully delivered to the recipient.|
| 03   | Cancelled       | The order has been cancelled by the user or vendor.|


{% enddocs %}

{% docs __dbtutils__ %}
# Our dbt project heavily relies on SQL, macros, especially
- `surrogate_key`
- `test_equality`
- `pivot`
- Multiple Doc-Blocks can be added in 1 .md file 
{% enddocs %}