/*
Ranking the Value of Dimensions by measures:
Examples:
=> Ranking Subscriptions plan by total Annul Recurring Revenue ARR or MRR
=> Ranking features by total usage ...
Top N Performers and Bottom N Performers
 */
--What are the 5 worst-performing features in term of ARR
WITH
	features_info AS (
		SELECT
			f.feature_name,
			COALESCE(SUM(s.arr_amount), 0) AS total_arr
		FROM
			analytics.fact_feature_usage f
			LEFT JOIN analytics.fact_subscriptions s ON s.subscription_id = f.subscription_id
		GROUP BY
			f.feature_name
	),
	ranking AS (
		SELECT
			feature_name,
			total_arr,
			ROW_NUMBER() OVER (
				ORDER BY
					total_arr
			) AS features_rank
		FROM
			features_info
	)
SELECT
	*
FROM
	ranking
WHERE
	features_rank <= 5;


--What are the 5 top-performing features in term of ARR
WITH
	features_info AS (
		SELECT
			f.feature_name,
			COALESCE(SUM(s.arr_amount), 0) AS total_arr
		FROM
			analytics.fact_feature_usage f
			LEFT JOIN analytics.fact_subscriptions s ON s.subscription_id = f.subscription_id
		GROUP BY
			f.feature_name
	),
	ranking AS (
		SELECT
			feature_name,
			total_arr,
			ROW_NUMBER() OVER (
				ORDER BY
					total_arr DESC
			) AS features_rank
		FROM
			features_info
	)
SELECT
	*
FROM
	ranking
WHERE
	features_rank <= 5;


-- the top 10 accounts with the highest Annul Recurring Revenue
WITH
	base_query AS (
		SELECT
			account_id,
			COALESCE(SUM(arr_amount), 0) AS total_arr,
			ROW_NUMBER() OVER (
				ORDER BY
					COALESCE(SUM(arr_amount), 0) DESC
			) AS accounts_ranking
		FROM
			analytics.fact_subscriptions
		GROUP BY
			account_id
	)
SELECT
	account_id,
	total_arr,
	accounts_ranking
FROM
	base_query
WHERE
	accounts_ranking <= 10
ORDER BY
	accounts_ranking;