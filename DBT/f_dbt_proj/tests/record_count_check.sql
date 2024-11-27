{% set expected_counts = {
    'cust': 5,
    'ordr': 5,
    'emp': 5
} %}

-- Test the count of records in each table
{% for table, count in expected_counts.items() %}
SELECT '{{ table }}' AS table_name,
       (SELECT COUNT(*) FROM {{ source('landing', table) }}) AS record_count,
       {{ count }} AS expected_count
WHERE (SELECT COUNT(*) FROM {{ source('landing', table) }}) < {{ count }}
{% if not loop.last %} UNION ALL {% endif %}
{% endfor %}
