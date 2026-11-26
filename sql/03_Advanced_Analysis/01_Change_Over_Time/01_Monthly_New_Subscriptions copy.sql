/*
-- ===============================================================================
Analysis: Monthly New Subscriptions
-- ===============================================================================

Business Question:
How many new subscriptions does RavenStack acquire each month?

Objective:
Analyze monthly subscription acquisition trends.

Data Sources:
- analytics.fact_subscriptions
- analytics.dim_dates

Metrics:
- New Subscriptions

-- ===============================================================================
 */
-- 1. Data investigation
-- 2. Main analysis
-- 3. Additional analysis
-- 4. Final results
* /
-- ===============================================================================
-- The Query:
-- ===============================================================================
WITH
    new_subscriptions AS (
        SELECT
            d.month_start,
            COUNT(s.subscription_id) AS new_subscriptions,
            COUNT(DISTINCT account_id) AS new_accounts,
            ROUND(COALESCE(SUM(mrr_amount), 0)) AS total_mrr
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
            d.month_start
    )
SELECT
    *,
    ROUND(
        100.0 * (
            total_mrr - LAG(total_mrr) OVER (
                ORDER BY
                    month_start
            )
        ) / NULLIF(
            LAG(total_mrr) OVER (
                ORDER BY
                    month_start
            ),
            0
        ),
        2
    ) AS mom_mrr_growth_pct
FROM
    new_subscriptions;


-- ============================================================================
-- Findings:
-- ============================================================================
/*
Record your findings after executing and interpreting the query.

1.
2.
3.

 */