set search_path to benchmark_schema, public;


SELECT * FROM benchmark_results;



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
        WHEN TRIM(etapa) = 'antes' THEN 1
        WHEN TRIM(etapa) = 'depois indices' THEN 2
        WHEN TRIM(etapa) = 'depois indices e otimizacao' THEN 3
        ELSE 4
    END;

