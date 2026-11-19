SELECT
    UPPER(churn_event_id),
    UPPER(account_id)
FROM
    analytics.dim_churn_events