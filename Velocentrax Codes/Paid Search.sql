--------------Paid Search Levels--------------------

select * from paid_search_omni_l1;

CREATE OR REPLACE TABLE paid_search_omni_l1 AS

WITH base AS (
    SELECT
        TO_DATE(MONTH, 'YYYY-MM') AS month_dt,
        YEAR(TO_DATE(MONTH, 'YYYY-MM')) AS yr,
        SEARCH_ENGINE,
        CAMPAIGN_ID,
        CAMPAIGN_NAME,
        SUM(IMPRESSIONS) AS impressions,
        SUM(CLICKS) AS clicks,
        SUM(COST) AS cost
    FROM paid_search_omni
    GROUP BY
        TO_DATE(MONTH, 'YYYY-MM'),
        YEAR(TO_DATE(MONTH, 'YYYY-MM')),
        SEARCH_ENGINE,
        CAMPAIGN_ID,
        CAMPAIGN_NAME
),

monthly AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        SEARCH_ENGINE,
        CAMPAIGN_ID,
        CAMPAIGN_NAME,
        impressions,
        clicks,
        cost,
        CASE WHEN impressions > 0 THEN clicks / impressions ELSE 0 END AS ctr,
        CASE WHEN clicks > 0 THEN cost / clicks ELSE 0 END AS avg_cpc
    FROM base
),

ytd AS (
    SELECT
        'YTD' AS time_granularity,
        null AS period,
        SEARCH_ENGINE,
        CAMPAIGN_ID,
        CAMPAIGN_NAME,
        SUM(impressions) AS impressions,
        SUM(clicks) AS clicks,
        SUM(cost) AS cost,
        CASE WHEN SUM(impressions) > 0 
             THEN SUM(clicks) / SUM(impressions) ELSE 0 END AS ctr,
        CASE WHEN SUM(clicks) > 0 
             THEN SUM(cost) / SUM(clicks) ELSE 0 END AS avg_cpc
    FROM base
    GROUP BY
        yr,
        SEARCH_ENGINE,
        CAMPAIGN_ID,
        CAMPAIGN_NAME
)

SELECT * FROM monthly
UNION ALL
SELECT * FROM ytd;
