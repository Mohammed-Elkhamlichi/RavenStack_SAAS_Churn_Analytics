-- Compare the Measure Values by Category
-- Examples:
-- Total Annule Reccuring Revenue ARR By Subscription Plan
-- Total Seats by Subscription Plan
-- Total ARR by Accounts ...
-- ******************************************
-- Total Annule Reccuring Revenue by Plan
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
-- Total Annule Reccuring Revenue ARR
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
    total_arr DESC;


-- Find Total Accounts
-- Total Seats
-- Total Annule Reccuring Revenue ARR
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
    total_arr DESC;


-- Find Total Accounts
-- Total Usage
-- Total Annule Reccuring Revenue ARR
-- By Feature Name
SELECT
    f.feature_name,
    COUNT(DISTINCT s.account_id) AS total_accounts,
    SUM(f.usage_count) AS total_usage,
    -- Format as text for display, or leave raw numeric if using in Power BI
    TO_CHAR(ROUND(SUM(s.arr_amount)), 'FM$999,999,999,999') AS total_arr
FROM
    analytics.fact_feature_usage f
    LEFT JOIN analytics.fact_subscriptions s ON s.subscription_id = f.subscription_id
GROUP BY
    f.feature_name,
    f.subscription_id
ORDER BY
    SUM(s.arr_amount) DESC NULLS LAST;