/*
===============================================================================
Analysis: Monthly Subscription Cancellations & Lost Revenue
===============================================================================

Business Question:
How many subscriptions and accounts cancel each month, how much recurring revenue is lost, and how does the churn trend evolve?

Key Metrics:
- Churned Subscriptions
- Churned Accounts
- Lost MRR
- Lost ARR
- Customer Churn Rate (%)
- Month-over-Month Change in Lost MRR (%)
===============================================================================
 */
WITH
    churned_subscriptions AS (
        SELECT
            d.month_start,
            COUNT(subscription_id) AS churned_subscriptions,
            COUNT(DISTINCT account_id) AS churned_accounts,
            COALESCE(SUM(mrr_amount), 0) AS lost_mrr,
            COALESCE(SUM(arr_amount), 0) AS lost_arr
        FROM
            analytics.dim_dates d
            -- subscription ends within the selected month
            LEFT JOIN analytics.fact_subscriptions s ON s.end_date IS NOT NULL
            AND s.end_date >= d.month_start
            AND s.end_date <= d.month_end
        GROUP BY
            d.month_start
    )
SELECT
    *,
    ROUND(
        100.0 * (
            churned_accounts - LAG(churned_accounts) OVER (
                ORDER BY
                    month_start
            )
        ) / NULLIF(
            LAG(churned_accounts) OVER (
                ORDER BY
                    month_start
            ),
            0
        ),
        2
    ) AS mom_churned_accounts_change_pct,
    ROUND(
        100.0 * (
            lost_mrr - LAG(lost_mrr) OVER (
                ORDER BY
                    month_start
            )
        ) / NULLIF(
            LAG(lost_mrr) OVER (
                ORDER BY
                    month_start
            ),
            0
        ),
        2
    ) AS mom_lost_mrr_change_pct
FROM
    churned_subscriptions