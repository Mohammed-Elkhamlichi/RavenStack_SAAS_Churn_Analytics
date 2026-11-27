/*
===============================================================================
Analysis: Subscription Plan & Billing Mix
===============================================================================

Business Question:
How does the distribution of new subscriptions and recurring revenue change across subscription plans (Basic, Pro, Enterprise) and billing frequencies (Monthly vs. Annual)?

Key Metrics:
- New Subscriptions by Plan
- New MRR by Plan
- Subscription Mix (%)
- Billing Frequency Distribution (%)
===============================================================================
 */
WITH
    monthly_plan_billing_metrics AS (
        SELECT
            d.month_start,
            s.plan_tier,
            s.billing_frequency,
            COUNT(s.subscription_id) AS new_subscriptions,
            COUNT(DISTINCT s.account_id) AS subscribing_accounts,
            ROUND(COALESCE(SUM(s.mrr_amount), 0), 2) AS new_mrr,
            ROUND(COALESCE(SUM(s.arr_amount), 0), 2) AS new_arr
        FROM
            analytics.dim_dates d
            LEFT JOIN analytics.fact_subscriptions s ON s.start_date >= d.month_start
            AND s.start_date <= d.month_end
        GROUP BY
            d.month_start,
            s.plan_tier,
            s.billing_frequency
    )
SELECT
    month_start,
    plan_tier,
    billing_frequency,
    new_subscriptions,
    ROUND(
        100.0 * new_subscriptions / NULLIF(
            SUM(new_subscriptions) OVER (
                PARTITION BY
                    month_start
            ),
            0
        ),
        2
    ) AS subscription_mix_pct,
    ROUND(
        100.0 * new_subscriptions / NULLIF(
            SUM(new_subscriptions) OVER (
                PARTITION BY
                    month_start,
                    billing_frequency
            ),
            0
        ),
        2
    ) AS billing_frequency_mix_pct,
    subscribing_accounts,
    new_mrr,
    new_arr
FROM
    monthly_plan_billing_metrics
ORDER BY
    month_start,
    plan_tier,
    billing_frequency;