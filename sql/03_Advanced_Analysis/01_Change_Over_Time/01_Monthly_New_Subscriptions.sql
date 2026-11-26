/*
===============================================================================
Analysis: Monthly Subscription Acquisition
===============================================================================

Business Question:
How many new subscriptions and accounts does RavenStack acquire each month,
how much new MRR do they generate, and how does acquisition evolve over time?

Key Metrics:
- New Subscriptions
- New Accounts
- New MRR
- Previous Month Subscriptions
- Month-over-Month Growth (%)
===============================================================================
 */
CREATE OR REPLACE VIEW
    reporting.vw_monthly_subscription_acquisition AS (
        WITH
            monthly_acquisition AS (
                -- Aggregate new subscriptions, accounts, and MRR by month
                SELECT
                    DATE_TRUNC('month', start_date)::DATE AS month_start,
                    COUNT(*) AS new_subscriptions,
                    COUNT(DISTINCT account_id) AS new_accounts,
                    SUM(mrr_amount) AS new_mrr
                FROM
                    analytics.fact_subscriptions
                WHERE
                    start_date IS NOT NULL
                GROUP BY
                    1
            )
            -- Compare monthly acquisition with the previous month
        SELECT
            month_start,
            new_subscriptions,
            new_accounts,
            new_mrr,
            LAG(new_subscriptions) OVER (
                ORDER BY
                    month_start
            ) AS previous_month_subscriptions,
            ROUND(
                100.0 * (
                    new_subscriptions - LAG(new_subscriptions) OVER (
                        ORDER BY
                            month_start
                    )
                ) / NULLIF(
                    LAG(new_subscriptions) OVER (
                        ORDER BY
                            month_start
                    ),
                    0
                ),
                2
            ) AS mom_growth_pct
        FROM
            monthly_acquisition
        ORDER BY
            month_start
    );