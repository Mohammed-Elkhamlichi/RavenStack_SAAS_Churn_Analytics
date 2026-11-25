/*
===============================================================================
Analysis: Monthly New Subscriptions
===============================================================================

Business Question:
How many new subscriptions does RavenStack acquire each month,
and how does the trend change over time?

Objective:
Analyze monthly subscription acquisition to identify growth
patterns and fluctuations.

Database:
PostgreSQL

Table:
analytics.fact_subscriptions

Key Columns:
- subscription_id
- start_date

SQL Concepts:
- DATE_TRUNC()
- COUNT(DISTINCT)
- GROUP BY
- ORDER BY
 */
-- ===============================================================================
-- The Query:
-- ===============================================================================
SELECT
    d.month_start,
    COUNT(s.subscription_id) AS total_subscriptions
FROM
    analytics.fact_subscriptions s
    -- The Dim_dates table contains a series of months,starting from the first month in our dataset to the last one;
    -- and contains 2 columns: -- month_start exp: 2023-01-01 -- and month_end exp: 2023-01-31
    RIGHT JOIN analytics.dim_dates d ON start_date IS NOT NULL
    AND s.start_date <= d.month_end
    AND s.start_date <= s.end_date
GROUP BY
    d.month_start
ORDER BY
    d.month_start;


-- ============================================================================
-- Findings:
-- ============================================================================
/*
Record your findings after executing and interpreting the query.

1.
2.
3.

 */