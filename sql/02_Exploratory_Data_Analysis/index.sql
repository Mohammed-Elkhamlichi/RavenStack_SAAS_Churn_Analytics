-- Total Annule Reccuring Revenue by Plan
SELECT
    plan_tier,
    COUNT(DISTINCT account_id) AS total_accounts,
    COUNT(seats) AS total_seats,
    TO_CHAR(ROUND(SUM(arr_amount)), 'FM$999,999,999,999') AS total_arr
FROM
    analytics.fact_subscriptions
GROUP BY
    plan_tier
ORDER BY
    total_arr DESC;


-- Finding the loyal clients 
-- & Calculate the Total ARR and MRR 
-- & Total seats for each account
CREATE VIEW
    IF NOT EXISTS
WITH
    loyal_clients AS (
        SELECT
            UPPER(account_id) AS account_id,
            MIN(start_date) AS first_start_date,
            SUM(seats) AS total_seats,
            SUM(mrr_amount) AS total_mrr,
            SUM(arr_amount) AS total_arr
        FROM
            analytics.fact_subscriptions
        WHERE
            end_date IS NULL
            AND end_date IS BETWEEN 2022 AND 2023
        GROUP BY
            account_id
        ORDER BY
            first_start_date
    )
SELECT
    *
FROM
    loyal_clients;