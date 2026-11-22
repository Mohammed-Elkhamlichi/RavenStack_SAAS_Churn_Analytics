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
    --	Calculate the Subscription Share % of each Billing Frequency out of each month's total subscriptions
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
    -- Calculate the Share % of each billing frequency out of each month total's total MRR 
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
    billing_frequency;


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
WITH
    subscription_aggregations AS (
        SELECT
            DATE_TRUNC('month', s.end_date)::DATE AS end_month_date,
            COUNT(DISTINCT s.account_id) AS churned_accounts,
            COUNT(s.subscription_id) AS churned_subscriptions,
            COALESCE(SUM(s.mrr_amount), 0) AS lost_mrr
        FROM
            analytics.fact_subscriptions s
        WHERE
            s.end_date IS NOT NULL
            AND s.end_date >= s.start_date
        GROUP BY
            end_month_date
    ),
    subscription_lagged AS (
        SELECT
            *,
            --		 Get The Previous Month Lost MRR
            LAG(lost_mrr) OVER (
                ORDER BY
                    end_month_date
            ) AS previous_lost_mrr
        FROM
            subscription_aggregations
    )
SELECT
    end_month_date,
    churned_accounts,
    churned_subscriptions,
    --	calculate the Average Lost MRR per Subscription
    ROUND(1.0 * lost_mrr / NULLIF(churned_subscriptions, 0), 2) AS avg_lost_mrr_per_sub,
    lost_mrr,
    --	previous Month lost MRR
    previous_lost_mrr,
    --	Lost MRR Change Value
    lost_mrr - previous_lost_mrr AS lost_mrr_change,
    --	Lost MRR Change Percentage
    ROUND(100.0 * (lost_mrr - previous_lost_mrr) / NULLIF(previous_lost_mrr, 0), 2) AS mom_lost_mrr_growth_pct
FROM
    subscription_lagged
ORDER BY
    end_month_date;


-- ----------------------------------------------------------------------------
-- Q5: Active Run-Rate Over Time (Monthly Calendar Grid)
-- Business Question: How many active accounts and how much active MRR/ARR are
--                    running in each calendar month across the full timeline?
-- Key Logic:         Generate a continuous monthly spine (generate_series) and
--                    match active subscriptions.
-- ----------------------------------------------------------------------------
WITH
    calendar_months AS (
        SELECT
            year_month_start::DATE AS year_month_start,
            -- get the end of each month we have in our month serie
            (year_month_start + INTERVAL '1 month - 1 day')::DATE AS year_month_end
        FROM
            -- create a series of months from the first month in our dataset to the last month 
            GENERATE_SERIES(
                -- get the first date in our dataset
                (
                    SELECT
                        DATE_TRUNC('month', MIN(start_date))
                    FROM
                        analytics.fact_subscriptions
                ),
                -- get the last date in our dataset
                (
                    SELECT
                        DATE_TRUNC('month', GREATEST(MAX(start_date), MAX(end_date)))
                    FROM
                        analytics.fact_subscriptions
                ),
                INTERVAL '1 month'
            ) AS year_month_start
    ),
    aggregations AS (
        SELECT
            cm.year_month_start,
            COUNT(DISTINCT s.account_id) AS active_accounts,
            COUNT(s.subscription_id) AS active_subscriptions,
            COALESCE(SUM(s.mrr_amount), 0) AS active_mrr,
            LAG(COALESCE(SUM(s.mrr_amount), 0)) OVER (
                ORDER BY
                    cm.year_month_start
            ) AS previous_active_mrr
        FROM
            calendar_months cm
            LEFT JOIN analytics.fact_subscriptions s ON (
                s.start_date IS NOT NULL
                AND s.start_date <= cm.year_month_end
            )
            AND (
                s.end_date IS NULL
                OR s.end_date >= cm.year_month_start
            )
            AND (
                s.end_date IS NULL
                OR s.end_date >= s.start_date
            )
        GROUP BY
            cm.year_month_start
        ORDER BY
            cm.year_month_start
    )
SELECT
    year_month_start,
    active_accounts,
    active_subscriptions,
    active_mrr,
    previous_active_mrr,
    --	the Active Monthly Recurring Revenue MRR Change Value
    active_mrr - previous_active_mrr AS active_mrr_change,
    --	the Active Monthly Recurring Revenue MRR Month of Month Growth Percentage
    ROUND(100.0 * (active_mrr - previous_active_mrr) / NULLIF(previous_active_mrr, 0), 2) AS mom_active_mrr_growth_pct
FROM
    aggregations;


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
SELECT
    DATE_TRUNC('month', signup_date)::DATE AS signup_month,
    COUNT(account_id) AS total_accounts,
    COALESCE(SUM(initial_seats), 0) AS total_seats,
    ROUND(COALESCE(AVG(initial_seats)), 0) AS avg_seats
FROM
    analytics.dim_accounts
GROUP BY
    signup_month
ORDER BY
    signup_month;


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