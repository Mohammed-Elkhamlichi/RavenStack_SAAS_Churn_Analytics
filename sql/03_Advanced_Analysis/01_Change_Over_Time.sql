/*
===============================================================================
Project:       RavenStack SaaS Subscription & Churn Analytics
Phase:         03_Advanced_Analysis - 01_Change_Over_Time.sql
Description:   Monthly time-series trend analysis across subscriptions, recurring
revenue (MRR/ARR), churn, account seats, feature usage, and
support tickets using DATE_TRUNC('month', ...) and LAG().
Tables Used:   analytics.dim_accounts
analytics.fact_subscriptions
analytics.fact_feature_usage
analytics.fact_support_tickets
analytics.churn_events
Modeling Rule: Aggregate each fact table to a single monthly grain before
applying window functions or joins to prevent fan-out duplication.
===============================================================================
 */
-- ============================================================================
-- SECTION 1: SUBSCRIPTION & REVENUE MOMENTUM (analytics.fact_subscriptions)
-- ============================================================================
-- ----------------------------------------------------------------------------
-- Q1: Monthly New Subscriptions & Starting Revenue Over Time
-- Business Question: How do monthly new subscriptions, distinct new accounts,
--                    starting MRR, and starting ARR trend month-over-month?
-- ----------------------------------------------------------------------------
WITH
    subscription_info AS (
        SELECT
            DATE_TRUNC('month', start_date)::DATE AS year_month_start,
            COUNT(subscription_id) AS total_subscriptions,
            COUNT(DISTINCT account_id) AS total_accounts,
            COALESCE(SUM(mrr_amount), 0) AS current_mrr
        FROM
            analytics.fact_subscriptions
        WHERE
            start_date IS NOT NULL
        GROUP BY
            year_month_start
    ),
    subscriptions_aggregations AS (
        SELECT
            year_month_start,
            total_subscriptions,
            total_accounts,
            current_mrr,
            LAG(current_mrr) OVER (
                ORDER BY
                    year_month_start
            ) AS previous_mrr
        FROM
            subscription_info
    )
SELECT
    year_month_start,
    total_subscriptions,
    total_accounts,
    current_mrr,
    previous_mrr,
    current_mrr - previous_mrr AS mrr_change,
    ROUND(100.0 * (current_mrr - previous_mrr) / NULLIF(previous_mrr, 0), 2) AS mom_mrr_growth_pct
FROM
    subscriptions_aggregations
ORDER BY
    year_month_start;


-- ----------------------------------------------------------------------------
-- Q2: Monthly New Revenue & Volume by Plan Tier
-- Business Question: How does monthly new MRR trend across Basic, Pro,
--                    and Enterprise plans?
-- Key Logic:         Group by month and plan_tier; use PARTITION BY plan_tier
--                    inside LAG() so each tier compares only to its own history.
-- ----------------------------------------------------------------------------
WITH
    subscription_info AS (
        SELECT
            DATE_TRUNC('month', start_date)::DATE AS year_month_start,
            plan_tier,
            COUNT(DISTINCT account_id) AS total_accounts,
            COUNT(subscription_id) AS total_subscriptions,
            COALESCE(SUM(mrr_amount), 0) AS total_mrr
        FROM
            analytics.fact_subscriptions
        WHERE
            start_date IS NOT NULL
        GROUP BY
            year_month_start,
            plan_tier
    ),
    subscription_mrr_lagged AS (
        SELECT
            *,
            LAG(total_mrr) OVER (
                PARTITION BY
                    plan_tier
                ORDER BY
                    year_month_start
            ) AS previous_mrr
        FROM
            subscription_info
    )
SELECT
    year_month_start,
    plan_tier,
    total_accounts,
    total_subscriptions,
    total_mrr,
    previous_mrr,
    total_mrr - previous_mrr AS mrr_change_value,
    ROUND(100 * (total_mrr - previous_mrr) / NULLIF(previous_mrr, 0), 2) AS mom_mrr_growth_pct
FROM
    subscription_mrr_lagged
ORDER BY
    year_month_start,
    plan_tier;


-- ----------------------------------------------------------------------------
-- Q3: Monthly Billing Frequency Mix (Monthly vs. Annual)
-- Business Question: How do monthly vs. annual subscription starts and revenue
--                    shift over time as a share of each month's new revenue?
-- Key Logic:         Group by month and billing_frequency; calculate monthly
--                    revenue share % with SUM(...) OVER (PARTITION BY month).
-- ----------------------------------------------------------------------------
WITH
    subscription_info AS (
        SELECT
            DATE_TRUNC('month', start_date)::DATE AS year_month_start,
            billing_frequency,
            COUNT(DISTINCT account_id) AS total_accounts,
            COUNT(subscription_id) AS total_subscriptions,
            -- Total MRR By Billing Frequency
            COALESCE(SUM(mrr_amount), 0) AS total_mrr
        FROM
            analytics.fact_subscriptions
        WHERE
            start_date IS NOT NULL
        GROUP BY
            year_month_start,
            billing_frequency
    )
SELECT
    year_month_start,
    billing_frequency,
    total_accounts,
    --	Calculate the Subscription Share % of each Billing Frequency of each month total subscription
    total_subscriptions,
    ROUND(
        100.0 * total_subscriptions / NULLIF(
            SUM(total_subscriptions) OVER (
                PARTITION BY
                    year_month_start
            ),
            0
        ),
        2
    ) AS subscription_share_pct,
    total_mrr,
    -- Calculate the Share % of each billing frequency of each month total MRR
    ROUND(
        100.0 * total_mrr / NULLIF(
            SUM(total_mrr) OVER (
                PARTITION BY
                    year_month_start
            ),
            0
        ),
        2
    ) AS mrr_share_pct
FROM
    subscription_info
ORDER BY
    year_month_start,
    billing_frequency
    -- ============================================================================
    -- SECTION 2: CHURN & ACTIVE RUN-RATE DYNAMICS
    -- ============================================================================
    -- ----------------------------------------------------------------------------
    -- Q4: Monthly Cancellations & Lost Recurring Revenue
    -- Business Question: How many subscriptions and distinct accounts end each
    --                    month, how much MRR/ARR is lost, and is churn accelerating?
    -- Key Logic:         Filter end_date IS NOT NULL, group by month of end_date,
    --                    and track MoM changes with LAG().
    -- ----------------------------------------------------------------------------
    -- ----------------------------------------------------------------------------
    -- Q5: Active Run-Rate Over Time (Monthly Calendar Grid)
    -- Business Question: How many active accounts and how much active MRR/ARR are
    --                    running in each calendar month across the full timeline?
    -- Key Logic:         Generate a continuous monthly spine (generate_series) and
    --                    match active subscriptions (start_date <= month_end AND
    --                    (end_date IS NULL OR end_date >= month_start)).
    -- ----------------------------------------------------------------------------
    -- ============================================================================
    -- SECTION 3: ACCOUNT ACQUISITION & SEAT FOOTPRINT (analytics.dim_accounts)
    -- ============================================================================
    -- ----------------------------------------------------------------------------
    -- Q6: Monthly Account Signups & Starting Seat Footprint
    -- Business Question: How do monthly account signups and total/average
    --                    initial_seats trend over time across newer cohorts?
    -- Key Logic:         Group dim_accounts by signup month and compare monthly
    --                    account volume and seat trends using LAG().
    -- ----------------------------------------------------------------------------
    -- ============================================================================
    -- SECTION 4: PRODUCT ENGAGEMENT & SUPPORT FRICTION
    -- ============================================================================
    -- ----------------------------------------------------------------------------
    -- Q7: Monthly Product Feature Usage Trends
    -- Business Question: How do total usage_count and distinct active accounts
    --                    trend each month, and which features are growing/declining?
    -- Key Logic:         Aggregate fact_feature_usage by month (and feature_name)
    --                    independently of subscriptions to avoid revenue fan-out.
    -- ----------------------------------------------------------------------------
    -- ----------------------------------------------------------------------------
    -- Q8: Monthly Support Ticket Volume & High-Severity Friction
    -- Business Question: How do monthly support ticket counts—especially urgent
    --                    and high priority tickets—trend over time?
    -- Key Logic:         Group fact_support_tickets by month, exclude the invalid
    --                    'priority' string value, and track MoM volume shifts.
    -- ----------------------------------------------------------------------------