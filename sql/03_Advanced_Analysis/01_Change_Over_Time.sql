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
    ROUND(100.0 * (total_mrr - previous_mrr) / NULLIF(previous_mrr, 0), 2) AS mom_mrr_growth_pct
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
    aggregations
ORDER BY
    year_month_start;


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
WITH
    account_signup_aggregation AS (
        SELECT
            DATE_TRUNC('month', signup_date)::DATE AS signup_month,
            -- Total new accounts
            COUNT(DISTINCT account_id) AS new_accounts,
            -- Total initial seats
            COALESCE(SUM(initial_seats), 0) AS total_initial_seats,
            -- Average initial seats per new account
            ROUND(1.0 * COALESCE(SUM(initial_seats), 0) / NULLIF(COUNT(DISTINCT account_id), 0), 2) AS avg_initial_seats
        FROM
            analytics.dim_accounts
        WHERE
            signup_date IS NOT NULL
        GROUP BY
            signup_month
    ),
    accounts_signup_lagged AS (
        SELECT
            signup_month,
            new_accounts,
            -- Previous month new accounts
            LAG(new_accounts) OVER (
                ORDER BY
                    signup_month
            ) AS previous_new_accounts,
            total_initial_seats,
            avg_initial_seats,
            -- Previous month total initial seats
            LAG(total_initial_seats) OVER (
                ORDER BY
                    signup_month
            ) AS previous_initial_seats
        FROM
            account_signup_aggregation
    )
SELECT
    signup_month,
    new_accounts,
    previous_new_accounts,
    -- New account MoM change value
    new_accounts - previous_new_accounts AS account_change,
    -- New account MoM growth percentage
    ROUND(100.0 * (new_accounts - previous_new_accounts) / NULLIF(previous_new_accounts, 0), 2) AS mom_account_growth_pct,
    total_initial_seats,
    avg_initial_seats,
    previous_initial_seats,
    -- Total initial seats MoM change value
    total_initial_seats - previous_initial_seats AS seats_change,
    -- Total initial seats MoM growth percentage
    ROUND(100.0 * (total_initial_seats - previous_initial_seats) / NULLIF(previous_initial_seats, 0), 2) AS mom_seats_growth_pct
FROM
    accounts_signup_lagged
ORDER BY
    signup_month;


-- ============================================================================
-- SECTION 4: PRODUCT ENGAGEMENT & SUPPORT FRICTION
-- ============================================================================
-- ----------------------------------------------------------------------------
-- Q7: Monthly Feature Usage Trends
-- Business Question: How do total usage_count and distinct active accounts
--                    trend each month, and which features are growing/declining?
-- Key Logic:         Aggregate fact_feature_usage by month (and feature_name)
--                    independently of subscriptions to avoid revenue fan-out.
-- ----------------------------------------------------------------------------
WITH
    feature_usage AS (
        SELECT
            DATE_TRUNC('month', usage_date)::date AS usage_month,
            feature_name,
            COUNT(DISTINCT subscription_id) AS total_subscriptions,
            COALESCE(SUM(usage_count), 0) AS total_usage,
            -- The Average Usage Per Subscription
            ROUND(1.0 * COALESCE(SUM(usage_count), 0) / NULLIF(COUNT(subscription_id), 0), 2) AS avg_usage_per_sub
        FROM
            analytics.fact_feature_usage
        WHERE
            usage_date IS NOT NULL
        GROUP BY
            usage_month,
            feature_name
    ),
    feature_usage_lagged AS (
        SELECT
            *,
            -- The Previous Feature Total Usage
            LAG(total_usage) OVER (
                PARTITION BY
                    feature_name
                ORDER BY
                    usage_month
            ) AS previous_total_usage
        FROM
            feature_usage
    ),
    feature_usage_growth AS (
        SELECT
            usage_month,
            feature_name,
            total_subscriptions,
            total_usage,
            avg_usage_per_sub,
            previous_total_usage,
            -- The Feature Total Usage Month Over Month Change Value
            total_usage - previous_total_usage AS usage_change,
            -- The Feature Total Usage Month Over Month Change Percentage
            ROUND(100.0 * (total_usage - previous_total_usage) / NULLIF(previous_total_usage, 0), 2) AS mom_usage_growth_pct
        FROM
            feature_usage_lagged
    )
SELECT
    *
FROM
    feature_usage_growth
ORDER BY
    usage_month,
    -- feature_2 ..., get the number from the feature name and order this column based on the feature number
    NULLIF(SPLIT_PART(feature_name, '_', 2), '')::INTEGER ASC NULLS LAST;


-- ----------------------------------------------------------------------------
-- Q8: Monthly Support Ticket Volume & High-Severity Friction
-- Business Question: How do monthly support ticket counts—especially urgent
--                    and high priority tickets—trend over time?
-- Key Logic:         Group fact_support_tickets by month, exclude the invalid
--                    'priority' string value, and track MoM volume shifts.
-- ----------------------------------------------------------------------------
WITH
    support_ticket_cleanup AS (
        SELECT
            ticket_id,
            account_id,
            CASE
            --Converting the date from this 0027-07-23 00:00:00 to this 2023-07-27
                WHEN EXTRACT(
                    YEAR
                    FROM
                        submitted_at
                ) < 100 THEN MAKE_DATE(
                    2000 + EXTRACT(
                        DAY
                        FROM
                            submitted_at
                    )::INT,
                    EXTRACT(
                        MONTH
                        FROM
                            submitted_at
                    )::INT,
                    EXTRACT(
                        YEAR
                        FROM
                            submitted_at
                    )::INT
                )
                ELSE submitted_at::DATE
            END AS submitted_date,
            LOWER(TRIM(priority)) AS clean_priority
        FROM
            analytics.fact_support_tickets
        WHERE
            submitted_at IS NOT NULL
            AND LOWER(TRIM(priority)) IN ('urgent', 'high', 'medium', 'low')
    ),
    support_ticket_aggregation AS (
        SELECT
            DATE_TRUNC('month', submitted_date)::DATE AS ticket_month,
            COUNT(ticket_id) AS total_tickets,
            COUNT(DISTINCT account_id) AS total_accounts,
            -- Filter and Count The Tickets With 'urgent' and 'high' priorities
            COUNT(ticket_id) FILTER (
                WHERE
                    clean_priority IN ('urgent', 'high')
            ) AS high_severity_tickets
        FROM
            support_ticket_cleanup
        GROUP BY
            ticket_month
    ),
    support_ticket_lagged AS (
        SELECT
            *,
            -- The Previous Total Tickets 
            LAG(total_tickets) OVER (
                ORDER BY
                    ticket_month
            ) AS previous_total_tickets,
            -- The Previous Total High Severity Tickets  
            LAG(high_severity_tickets) OVER (
                ORDER BY
                    ticket_month
            ) AS previous_high_severity_tickets
        FROM
            support_ticket_aggregation
    ),
    support_ticket_growth AS (
        SELECT
            *,
            -- all tickets involve here
            -- The Total Ticket MoM Change Value
            total_tickets - previous_total_tickets AS ticket_change,
            -- The Support Ticket MoM Change Percentage
            ROUND(100.0 * (total_tickets - previous_total_tickets) / NULLIF(previous_total_tickets, 0), 2) AS mom_ticket_growth_pct,
            -- Only High Severity Tickets ('urgent','high') involve here
            -- The Total High Severity Ticket MoM Change Value
            high_severity_tickets - previous_high_severity_tickets AS high_severity_tickets_change,
            -- The Total High Severity Ticket MoM Change Percentage
            ROUND(
                100.0 * (high_severity_tickets - previous_high_severity_tickets) / NULLIF(previous_high_severity_tickets, 0),
                2
            ) AS mom_high_severity_tickets_growth_pct,
            -- Calculate the High Severity Tickets Percentage Share from the Total Tickets
            ROUND(100.0 * high_severity_tickets / NULLIF(total_tickets, 0), 2) AS high_severity_share_pct
        FROM
            support_ticket_lagged
    )
SELECT
    ticket_month,
    total_accounts,
    total_tickets,
    previous_total_tickets,
    ticket_change,
    mom_ticket_growth_pct,
    high_severity_tickets,
    previous_high_severity_tickets,
    high_severity_tickets_change,
    mom_high_severity_tickets_growth_pct,
    high_severity_share_pct
FROM
    support_ticket_growth
ORDER BY
    ticket_month;