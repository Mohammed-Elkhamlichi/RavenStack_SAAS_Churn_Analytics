-- Explore  all Objects in the DataBase
SELECT
    *
FROM
    INFORMATION_SCHEMA.TABLES;


-- Explore  all Columns in the DataBase
SELECT
    *
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    table_name = 'fact_subscriptions';