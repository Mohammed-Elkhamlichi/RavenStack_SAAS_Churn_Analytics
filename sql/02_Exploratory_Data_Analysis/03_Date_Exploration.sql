-- identify the earliest and latest dates (boundarais)
-- ****************************************************
-- Subscriptions boundarais
-- ****************************************************
-- "2023-01-09", "2024-12-31"
SELECT
    MIN(start_date) AS first_sub_date,
    MAX(start_date) AS last_sub_date
FROM
    analytics.fact_subscriptions;

-- ****************************************************
-- Accounts boundarais
-- ****************************************************
-- "2023-01-02", "2024-12-31"
SELECT
    MIN(signup_date) AS first_signup_date,
    MAX(signup_date) AS last_signup_date
FROM
    analytics.dim_accounts;

-- ****************************************************
-- Churn Events boundarais
-- ****************************************************
-- "2023-01-25", "2024-12-31"
SELECT
    MIN(churn_date) AS first_churn_date,
    MAX(churn_date) AS last_churn_date
FROM
    analytics.dim_churn_events;