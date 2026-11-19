-- *************************************
-- analytics.dim_accounts TABLE
-- *************************************
-- all industries:
-- "Cybersecurity" - "EdTech" - "DevTools" - "HealthTech" - "FinTech"
SELECT DISTINCT
    industry
FROM
    analytics.dim_accounts;

-- all Countries the Users Come From:
-- "AU" - "CA" - "IN" - "UK" - "US" - "FR" - "DE"
SELECT DISTINCT
    country
FROM
    analytics.dim_accounts;

-- all Referral Sources: 
-- "partner" - "event" - "ads" - "organic" - "other"
SELECT DISTINCT
    referral_source
FROM
    analytics.dim_accounts;

-- *************************************
-- analytics.fact_subscriptions TABLE
-- *************************************
-- All Subscription Plans: 
-- "Basic" - "Enterprise" - "Pro"
SELECT DISTINCT
    plan_tier
FROM
    analytics.fact_subscriptions;

-- All billing Frequences:
-- "annual" - "monthly"
SELECT DISTINCT
    billing_frequency
FROM
    analytics.fact_subscriptions;

-- *************************************
-- analytics.fact_feature_usage TABLE
-- *************************************
-- Explore Feature Names:
SELECT DISTINCT
    feature_name
FROM
    analytics.fact_feature_usage;

-- *************************************
-- analytics.fact_support_tickets TABLE
-- *************************************
-- All Priorities:
-- "priority" - "medium" - "urgent" - "high" - "low"
SELECT DISTINCT
    priority
FROM
    analytics.fact_support_tickets;