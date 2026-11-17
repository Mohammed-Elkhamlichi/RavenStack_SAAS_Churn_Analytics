-- =========================================================================
-- MASTER SETUP SCRIPT: RavenStack B2B SaaS Analytics Pipeline
-- Description: Creates schemas, staging tables, star schema (dimensions & facts),
--              and handles data ingestion & transformation.
-- Note: Ensure you have created the database `ravenstack_db` first and connected to it.
-- =========================================================================
-- =========================================================================
-- STEP 1: CREATE SCHEMAS
-- We separate raw data ingestion (staging) from clean reporting data (analytics).
-- =========================================================================
CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS analytics;

-- =========================================================================
-- STEP 2: CREATE STAGING TABLES (The Raw Landing Zone)
-- All columns are defined as TEXT or VARCHAR to prevent import failures 
-- due to formatting or date quirks in raw CSV files.
-- =========================================================================
-- 2.1 Staging Accounts
DROP TABLE IF EXISTS staging.accounts CASCADE;

CREATE TABLE
    staging.accounts (
        account_id TEXT,
        account_name TEXT,
        industry TEXT,
        country TEXT,
        signup_date TEXT,
        referral_source TEXT,
        plan_tier TEXT,
        seats TEXT,
        is_trial TEXT,
        churn_flag TEXT
    )
    -- 2.2 Staging Subscriptions
DROP TABLE IF EXISTS staging.subscriptions CASCADE;

CREATE TABLE
    staging.subscriptions (
        subscription_id TEXT,
        account_id TEXT,
        start_date TEXT,
        end_date TEXT,
        plan_tier TEXT,
        seats TEXT,
        mrr_amount TEXT,
        arr_amount TEXT,
        is_trial TEXT,
        upgrade_flag TEXT,
        downgrade_flag TEXT,
        churn_flag TEXT,
        billing_frequency TEXT,
        auto_renew_flag TEXT
    );

-- 2.3 Staging Feature Usage
DROP TABLE IF EXISTS staging.feature_usage CASCADE;

CREATE TABLE
    staging.feature_usage (
        usage_id TEXT,
        subscription_id TEXT,
        usage_date TEXT,
        feature_name TEXT,
        usage_count TEXT,
        usage_duration_secs TEXT,
        error_count TEXT,
        is_beta_feature TEXT
    );

-- 2.4 Staging Support Tickets
DROP TABLE IF EXISTS staging.support_tickets CASCADE;

CREATE TABLE
    staging.support_tickets (
        ticket_id TEXT,
        account_id TEXT,
        submitted_at TEXT,
        closed_at TEXT,
        resolution_time_hours TEXT,
        priority TEXT,
        first_response_time_minutes TEXT,
        satisfaction_score TEXT,
        escalation_flag TEXT
    );

-- 2.5 Staging Churn Events
DROP TABLE IF EXISTS staging.churn_events CASCADE;

CREATE TABLE
    staging.churn_events (
        churn_event_id TEXT,
        account_id TEXT,
        churn_date TEXT,
        reason_code TEXT,
        refund_amount_usd TEXT,
        preceding_upgrade_flag TEXT,
        preceding_downgrade_flag TEXT,
        is_reactivation TEXT,
        feedback_text TEXT
    );

-- =========================================================================
-- STEP 3: LOAD RAW DATA INTO STAGING (COPY Commands)
-- Run these commands in your PostgreSQL client (adjust file paths as needed).
-- Note: 'HEADER' tells PostgreSQL to skip the first header row of the CSV.
-- =========================================================================
/*

\COPY staging.accounts FROM 'YOUR-PATH-HERE\data\raw\ravenstack_accounts.csv' WITH (FORMAT CSV, HEADER TRUE);

\COPY staging.subscriptions FROM 'YOUR-PATH-HERE\data\raw\ravenstack_subscriptions.csv' WITH (FORMAT csv, HEADER true);

\COPY staging.feature_usage FROM 'YOUR-PATH-HERE\data\raw\ravenstack_feature_usage.csv' WITH (FORMAT csv, HEADER true);

\COPY staging.support_tickets FROM 'YOUR-PATH-HERE\data\raw\ravenstack_support_tickets.csv' WITH (FORMAT csv, HEADER true);

\COPY staging.churn_events FROM 'YOUR-PATH-HERE\data\raw\ravenstack_churn_events.csv' WITH (FORMAT csv, HEADER true);
 */
-- =========================================================================
-- STEP 4: CREATE STAR SCHEMA TABLES (The Analytics Layer)
-- Applying strict data types, Primary Keys, and Foreign Key constraints.
-- =========================================================================
-- 4.1 Dimension: Accounts
DROP TABLE IF EXISTS analytics.dim_accounts CASCADE;

CREATE TABLE
    analytics.dim_accounts (
        account_id VARCHAR(50) PRIMARY KEY,
        account_name VARCHAR(100) NOT NULL,
        industry VARCHAR(50) NOT NULL,
        country VARCHAR(10) NOT NULL,
        signup_date DATE NOT NULL,
        referral_source VARCHAR(50) NOT NULL,
        initial_plan VARCHAR(50) NOT NULL,
        initial_seats INT NOT NULL,
        is_trial BOOLEAN NOT NULL,
        churn_flag BOOLEAN NOT NULL
    );

-- 4.2 Dimension: Date Calendar Spine
DROP TABLE IF EXISTS analytics.dim_date CASCADE;

CREATE TABLE
    analytics.dim_date (
        date_key DATE PRIMARY KEY,
        YEAR INT NOT NULL,
        quarter INT NOT NULL,
        MONTH INT NOT NULL,
        month_name VARCHAR(20) NOT NULL,
        day_of_week VARCHAR(20) NOT NULL,
        is_weekend BOOLEAN NOT NULL
    );

-- 4.3 Fact: Subscriptions (Revenue & Plan Changes)
DROP TABLE IF EXISTS analytics.fact_subscriptions CASCADE;

CREATE TABLE
    analytics.fact_subscriptions (
        subscription_id VARCHAR(50) PRIMARY KEY,
        account_id VARCHAR(50) NOT NULL REFERENCES analytics.dim_accounts (account_id),
        start_date DATE NOT NULL,
        end_date DATE, -- NULL if currently active
        plan_tier VARCHAR(50) NOT NULL,
        seats INT NOT NULL,
        mrr_amount NUMERIC(10, 2) NOT NULL,
        arr_amount NUMERIC(10, 2) NOT NULL,
        is_trial BOOLEAN NOT NULL,
        upgrade_flag BOOLEAN NOT NULL,
        downgrade_flag BOOLEAN NOT NULL,
        churn_flag BOOLEAN NOT NULL,
        billing_frequency VARCHAR(20) NOT NULL,
        auto_renew_flag BOOLEAN NOT NULL
    );

-- 4.4 Fact: Feature Usage (Product Telemetry)
DROP TABLE IF EXISTS analytics.fact_feature_usage CASCADE;

CREATE TABLE
    analytics.fact_feature_usage (
        usage_id VARCHAR(50) PRIMARY KEY,
        subscription_id VARCHAR(50) NOT NULL REFERENCES analytics.fact_subscriptions (subscription_id),
        usage_date DATE NOT NULL,
        feature_name VARCHAR(50) NOT NULL,
        usage_count INT NOT NULL,
        usage_duration_secs INT NOT NULL,
        error_count INT NOT NULL,
        is_beta_feature BOOLEAN NOT NULL
    );

-- 4.5 Fact: Support Tickets (Customer Friction)
DROP TABLE IF EXISTS analytics.fact_support_tickets CASCADE;

CREATE TABLE
    analytics.fact_support_tickets (
        ticket_id VARCHAR(50) PRIMARY KEY,
        account_id VARCHAR(50) NOT NULL REFERENCES analytics.dim_accounts (account_id),
        submitted_at TIMESTAMP NOT NULL,
        closed_at TIMESTAMP NOT NULL,
        resolution_time_hours NUMERIC(10, 2) NOT NULL,
        priority VARCHAR(20) NOT NULL,
        first_response_time_minutes INT NOT NULL,
        satisfaction_score INT, -- Can be NULL if customer didn't leave CSAT score
        escalation_flag BOOLEAN NOT NULL
    );

-- =========================================================================
-- STEP 5: TRANSFORM & LOAD DATA INTO ANALYTICS TABLES
-- Casting TEXT columns from staging into clean data types (DATE, NUMERIC, BOOLEAN)
-- =========================================================================
-- 5.1 Load dim_accounts
INSERT INTO
    analytics.dim_accounts (
        account_id,
        account_name,
        industry,
        country,
        signup_date,
        referral_source,
        initial_plan,
        initial_seats,
        is_trial,
        churn_flag
    )
SELECT
    account_id,
    account_name,
    industry,
    country,
    TO_DATE(signup_date, 'YYYY-MM-DD')::DATE,
    referral_source,
    plan_tier,
    seats::INT,
    is_trial::BOOLEAN,
    churn_flag::BOOLEAN
FROM
    staging.accounts;

-- 5.2 Load fact_subscriptions
INSERT INTO
    analytics.fact_subscriptions (
        subscription_id,
        account_id,
        start_date,
        end_date,
        plan_tier,
        seats,
        mrr_amount,
        arr_amount,
        is_trial,
        upgrade_flag,
        downgrade_flag,
        churn_flag,
        billing_frequency,
        auto_renew_flag
    )
SELECT
    subscription_id,
    account_id,
    TO_DATE(start_date, 'YYYY-MM-DD')::DATE,
    TO_DATE(NULLIF(end_date, ''), 'YYYY-MM-DD')::DATE, -- Converts empty strings in CSV to proper SQL NULLs
    plan_tier,
    seats::INT,
    mrr_amount::NUMERIC(10, 2),
    arr_amount::NUMERIC(10, 2),
    is_trial::BOOLEAN,
    upgrade_flag::BOOLEAN,
    downgrade_flag::BOOLEAN,
    churn_flag::BOOLEAN,
    billing_frequency,
    auto_renew_flag::BOOLEAN
FROM
    staging.subscriptions;

-- 5.3 Load fact_feature_usage
INSERT INTO
    analytics.fact_feature_usage (
        usage_id,
        subscription_id,
        usage_date,
        feature_name,
        usage_count,
        usage_duration_secs,
        error_count,
        is_beta_feature
    )
SELECT
    usage_id,
    subscription_id,
    TO_DATE(usage_date, 'YYYY-MM-DD')::DATE,
    feature_name,
    usage_count::INT,
    usage_duration_secs::INT,
    error_count::INT,
    is_beta_feature::BOOLEAN
FROM
    staging.feature_usage;

-- 5.4 Load fact_support_tickets
INSERT INTO
    analytics.fact_support_tickets (
        ticket_id,
        account_id,
        submitted_at,
        closed_at,
        resolution_time_hours,
        priority,
        first_response_time_minutes,
        satisfaction_score,
        escalation_flag
    )
SELECT
    ticket_id,
    account_id,
    TO_TIMESTAMP(submitted_at, 'YYYY-MM-DD')::TIMESTAMP,
    TO_TIMESTAMP(closed_at, 'YYYY-MM-DD HH24:MI:SS')::TIMESTAMP,
    resolution_time_hours::NUMERIC(10, 2),
    priority,
    first_response_time_minutes::INT,
    NULLIF(satisfaction_score, '')::INT, -- Handles unrated tickets cleanly
    escalation_flag::BOOLEAN
FROM
    staging.support_tickets;

-- =========================================================================
-- SETUP COMPLETE! Your star schema is now ready for analytical queries & MRR calculations.
-- =========================================================================