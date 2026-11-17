-- US Users
SELECT
    CONCAT(COUNT(*), ' US Users')
FROM
    analytics.dim_accounts a
WHERE
    a.country = 'US';