set search_path to benchmark_schema, public;

SELECT 
    query_name,
    etapa,
    planning_time,
    execution_time,
    total_time,
    total_cost,
    rows_returned,
    buffers_hit,
    buffers_read
FROM benchmark_results
ORDER BY 
    query_name,
    CASE 
        WHEN etapa = 'antes' THEN 1
        WHEN etapa = 'depois' THEN 2
        ELSE 3
    END;

