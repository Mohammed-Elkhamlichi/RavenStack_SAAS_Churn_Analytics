-- *****************************
-- Accounts Table
-- *****************************
-- Total Accounts
-- 500
SELECT
    COUNT(DISTINCT account_id) AS total_accounts
FROM
    analytics.dim_accounts;

-- Total Seats
-- 10280
SELECT
    SUM(initial_seats) AS total_seats
FROM
    analytics.dim_accounts;

-- Avg Seats per account
-- 20.56
SELECT
    AVG(initial_seats) AS avg_seats_per_account
FROM
    analytics.dim_accounts;

-- *****************************
-- Subscriptions Table
-- *****************************
-- Total Subscriptions
SELECT
    COUNT(subscription_id) AS total_subscription
FROM
    analytics.fact_subscriptions;

-- Total Plans
SELECT
    COUNT(DISTINCT plan_tier) AS total_plans
FROM
    analytics.fact_subscriptions;

-- Total Monthly Recurring Revenue MRR
SELECT
    SUM(DISTINCT mrr_amount) AS total_mrr_amount
FROM
    analytics.fact_subscriptions;

-- Total Annule Recurring Revenue MRR
SELECT
    SUM(DISTINCT arr_amount) AS total_arr_amount
FROM
    analytics.fact_subscriptions;

-- *****************************
-- Churn Events Table
-- *****************************
-- Total Refund Amount USD
SELECT
    SUM(refund_amount_usd) AS total_refund_usd
FROM
    analytics.dim_churn_events;

-- *****************************
-- Feature Usage Table
-- *****************************
-- Total features
SELECT
    COUNT(DISTINCT feature_name) AS total_features
FROM
    analytics.fact_feature_usage;

-- *****************************
-- Support Tickets Table
-- *****************************
-- Total features
SELECT
    AVG(DISTINCT resolution_time_hours)::NUMERIC(10, 2) AS avg_resolution_time_hours
FROM
    analytics.fact_support_tickets;