/*
===============================================================================
Analysis: Monthly Subscription Acquisition
===============================================================================

Business Question:
How many new subscriptions and subscribing_accounts does RavenStack acquire each month,
how much new MRR do they generate, and how does acquisition evolve over time?

Key Metrics:
- New Subscriptions
- New subscribing_accounts
- New MRR
- Previous Month Subscriptions
- Month-over-Month Growth (%)
===============================================================================
 */
WITH
    monthly_acquisition AS (
        SELECT
            d.month_start,
            -- total new subscriptions
            COUNT(subscription_id) AS new_subscriptions,
            -- total new subscribing_accounts
            COUNT(DISTINCT account_id) AS subscribing_accounts,
            -- total new Monthly Recurring Revenue MRR
            ROUND(COALESCE(SUM(mrr_amount), 0), 2) AS new_mrr
        FROM
            analytics.dim_dates d
            /* 
            join the dim_dates table that contains all the months series 
            from the first month to the last one in our dataset; 
            with the fact_subscription table (subscriptions info)
             */
            LEFT JOIN analytics.fact_subscriptions s ON s.start_date >= d.month_start
            AND s.start_date <= d.month_end
        GROUP BY
            d.month_start
    ),
    monthly_previous_month_subscriptions AS (
        SELECT
            *,
            -- The Previous Month New Subscriptions
            LAG(new_subscriptions) OVER (
                ORDER BY
                    month_start
            ) AS previous_month_subscriptions
        FROM
            monthly_acquisition
    ),
    monthly_growth AS (
        SELECT
            *,
            -- the New Subscriptions Month Over Month Growth Value
            new_subscriptions - previous_month_subscriptions AS subscriptions_growth,
            -- The New Subscriptions Month Over Month Growth Percentage
            ROUND(
                100.0 * (new_subscriptions - previous_month_subscriptions) / NULLIF(previous_month_subscriptions, 0),
                2
            ) AS mom_subscription_growth_pct
        FROM
            monthly_previous_month_subscriptions
    )
SELECT
    month_start,
    subscribing_accounts,
    new_subscriptions,
    new_mrr,
    previous_month_subscriptions,
    subscriptions_growth,
    mom_subscription_growth_pct
FROM
    monthly_growth