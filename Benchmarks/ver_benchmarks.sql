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
        WHEN TRIM(etapa) = 'depois_s_seqscan' THEN 2
        WHEN TRIM(etapa) = 'depois_c_seqscan' THEN 3
        WHEN TRIM(etapa) = 'depois indices e otimizacao' THEN 4
        ELSE 5
    END;

