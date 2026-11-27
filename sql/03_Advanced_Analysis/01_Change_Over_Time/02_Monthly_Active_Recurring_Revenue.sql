/*
===============================================================================
Analysis: Monthly Active Recurring Revenue
===============================================================================

Business Question:
How do active accounts, Monthly Recurring Revenue (MRR), 
and Annual Recurring Revenue (ARR) evolve month over month?

Key Metrics:
- Active Accounts
- Active Subscriptions
- Active MRR
- Active ARR
===============================================================================
 */
SELECT
    d.month_start,
    COUNT(subscription_id) AS active_subscriptions,
    COUNT(DISTINCT account_id) AS active_accounts,
    ROUND(COALESCE(SUM(mrr_amount), 0), 2) AS active_mrr,
    ROUND(COALESCE(SUM(arr_amount), 0), 2) AS active_arr
FROM
    analytics.dim_dates d
    LEFT JOIN analytics.fact_subscriptions s ON s.start_date <= d.month_end
    AND (
        s.end_date IS NULL
        OR s.end_date >= d.month_end
    )
GROUP BY
    d.month_start