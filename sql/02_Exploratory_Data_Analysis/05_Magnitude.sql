-- Compare the Measure Values by Category
-- Examples:
-- Total Annule Recurring Revenue ARR By Subscription Plan
-- Total Seats by Subscription Plan
-- Total ARR by Accounts ...
-- ******************************************
-- Total Annule Recurring Revenue by Plan
-- ******************************************
SELECT
    plan_tier,
    COUNT(DISTINCT account_id) AS total_accounts,
    SUM(seats) AS total_seats,
    TO_CHAR(ROUND(SUM(arr_amount)), 'FM$999,999,999,999') AS total_arr
FROM
    analytics.fact_subscriptions
GROUP BY
    plan_tier
ORDER BY
    total_arr DESC;


-- ******************************************
-- Calculating The Total ARR,
-- Total Seats 
-- and the First Start Date per Account
-- ******************************************
WITH
    accounts AS (
        SELECT
            UPPER(account_id) AS account_id,
            MIN(start_date) AS first_start_date,
            SUM(seats) AS total_seats,
            TO_CHAR(ROUND(SUM(arr_amount)), 'FM$999,999,999,999') AS total_arr
        FROM
            analytics.fact_subscriptions
        WHERE
            end_date IS NULL
        GROUP BY
            account_id
        ORDER BY
            first_start_date
    )
SELECT
    *
FROM
    accounts;


-- Find Total Accounts
-- Total Seats
-- Total Annule Recurring Revenue ARR
-- By Countries
SELECT
    a.country,
    COUNT(DISTINCT s.account_id) AS total_accounts,
    SUM(s.seats) total_seats,
    TO_CHAR(ROUND(SUM(s.arr_amount)), 'FM$999,999,999,999') AS total_arr
FROM
    analytics.fact_subscriptions s
    LEFT JOIN analytics.dim_accounts a ON a.account_id = s.account_id
GROUP BY
    a.country
ORDER BY
    SUM(s.arr_amount) DESC;


-- Find Total Accounts
-- Total Seats
-- Total Annule Recurring Revenue ARR
-- By Industry
SELECT
    a.industry,
    COUNT(DISTINCT s.account_id) AS total_accounts,
    SUM(s.seats) total_seats,
    TO_CHAR(ROUND(SUM(s.arr_amount)), 'FM$999,999,999,999') AS total_arr
FROM
    analytics.fact_subscriptions s
    LEFT JOIN analytics.dim_accounts a ON a.account_id = s.account_id
GROUP BY
    a.industry
ORDER BY
    SUM(s.arr_amount) DESC;


-- Find Total Accounts
-- Total Usage
-- Total Annule Recurring Revenue ARR
-- By Feature Name
WITH
    base_query AS (
        SELECT
            f.feature_name,
            s.subscription_id,
            s.account_id,
            s.arr_amount,
            SUM(f.usage_count) AS feature_usage
        FROM
            analytics.fact_feature_usage f
            LEFT JOIN analytics.fact_subscriptions s ON s.subscription_id = f.subscription_id
        GROUP BY
            f.feature_name,
            s.subscription_id,
            s.account_id,
            s.arr_amount
    )
SELECT
    feature_name,
    COUNT(DISTINCT account_id) AS total_accounts,
    SUM(feature_usage) AS total_usage,
    -- Format as text for display
    TO_CHAR(ROUND(SUM(arr_amount)), 'FM$999,999,999,999') AS total_arr
FROM
    base_query
GROUP BY
    feature_name
ORDER BY
    SUM(arr_amount) DESC NULLS LAST;


-- magnitude analysis of total subscriptions, 
-- distinct accounts, MRR, ARR, 
-- and percentage share by plan_tier and billing_frequency.
WITH
    base_query AS (
        SELECT
            plan_tier,
            billing_frequency,
            COUNT(DISTINCT account_id) AS distinct_accounts,
            COUNT(subscription_id) AS total_subscriptions,
            COALESCE(SUM(arr_amount), 0) total_arr,
            COALESCE(SUM(mrr_amount), 0) total_mrr
        FROM
            analytics.fact_subscriptions
        GROUP BY
            plan_tier,
            billing_frequency
    )
SELECT
    plan_tier,
    billing_frequency,
    distinct_accounts,
    total_subscriptions,
    total_arr,
    ROUND((total_arr / SUM(total_arr) OVER ()) * 100, 2) AS arr_share_pct,
    total_mrr,
    ROUND((total_mrr / SUM(total_mrr) OVER ()) * 100, 2) AS mrr_share_pct
FROM
    base_query
ORDER BY
    total_arr DESC NULLS LAST,
    total_mrr DESC NULLS LAST;