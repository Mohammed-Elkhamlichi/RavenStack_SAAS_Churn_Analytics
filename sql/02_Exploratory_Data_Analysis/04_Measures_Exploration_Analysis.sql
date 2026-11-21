-- *****************************
-- Accounts Table
-- *****************************
-- Total Accounts
SELECT
    'Total Accounts' AS measure_name,
    COUNT(DISTINCT account_id) AS measure_value
FROM
    analytics.dim_accounts
UNION ALL
-- *****************************
-- Total Seats
SELECT
    'Total Seats',
    SUM(initial_seats)
FROM
    analytics.dim_accounts
UNION ALL
-- *****************************
-- Avg Seats per account
SELECT
    'Avg Seats per account',
    AVG(initial_seats)::NUMERIC(10, 2)
FROM
    analytics.dim_accounts
UNION ALL
-- *****************************
-- Subscriptions Table
-- *****************************
-- Total Subscriptions
SELECT
    'Total Subscriptions',
    COUNT(subscription_id)
FROM
    analytics.fact_subscriptions
UNION ALL
-- *****************************
-- Total Plans
SELECT
    'Total Plans',
    COUNT(DISTINCT plan_tier)
FROM
    analytics.fact_subscriptions
UNION ALL
-- *****************************
-- Total Monthly Recurring Revenue MRR
SELECT
    'Total Monthly Recurring Revenue MRR',
    ROUND(SUM(mrr_amount))
FROM
    analytics.fact_subscriptions
UNION ALL
-- *****************************
-- Total Annule Recurring Revenue ARR
SELECT
    'Total Annule Recurring Revenue ARR',
    ROUND(SUM(arr_amount))
FROM
    analytics.fact_subscriptions
UNION ALL
-- *****************************
-- Churn Events Table
-- *****************************
-- Total Refund Amount USD
SELECT
    'Total Refund Amount USD',
    SUM(refund_amount_usd)
FROM
    analytics.dim_churn_events
UNION ALL
-- *****************************
-- Feature Usage Table
-- *****************************
-- Total features
SELECT
    'Total Features',
    COUNT(DISTINCT feature_name)
FROM
    analytics.fact_feature_usage
UNION ALL
-- *****************************
-- Support Tickets Table
-- *****************************
-- Average Resolution Time in Hours
SELECT
    'Average Resolution Time in Hours',
    AVG(DISTINCT resolution_time_hours)::NUMERIC(10, 2)
FROM
    analytics.fact_support_tickets;