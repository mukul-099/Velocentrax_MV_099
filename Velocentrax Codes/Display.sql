-------------------------Display--------------------------------

CREATE OR REPLACE TABLE display_omni_l1 AS

WITH base AS (
    SELECT
        TO_DATE(MONTH, 'YYYY-MM') AS month_dt,
        YEAR(TO_DATE(MONTH, 'YYYY-MM')) AS yr,
        PACKAGE,

        SUM(IMPRESSIONS) AS impressions,
        SUM(REACH) AS reach,
        SUM(VIEWABLE_IMPRESSIONS) AS viewable_impressions,
        SUM(CLICKS) AS clicks,
        SUM(COST) AS cost,
        SUM(POST_VIEW_SESSIONS) AS post_view_sessions,
        SUM(POST_CLICK_SESSIONS) AS post_click_sessions

    FROM display_omni
    GROUP BY
        TO_DATE(MONTH, 'YYYY-MM'),
        YEAR(TO_DATE(MONTH, 'YYYY-MM')),
        PACKAGE
),

monthly AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        PACKAGE,

        impressions,
        reach,
        CASE 
            WHEN reach > 0 THEN impressions / reach 
            ELSE 0 
        END AS frequency,

        viewable_impressions,
        CASE 
            WHEN impressions > 0 THEN viewable_impressions / impressions 
            ELSE 0 
        END AS viewability_rate,

        clicks,
        cost,
        CASE 
            WHEN impressions > 0 THEN clicks / impressions 
            ELSE 0 
        END AS ctr,

        CASE 
            WHEN clicks > 0 THEN cost / clicks 
            ELSE 0 
        END AS avg_cpc,

        CASE 
            WHEN impressions > 0 THEN (cost / impressions) * 1000 
            ELSE 0 
        END AS cpm,

        post_view_sessions,
        post_click_sessions
    FROM base
),

ytd AS (
    SELECT
        'YTD' AS time_granularity,
        null AS period,
        PACKAGE,

        SUM(impressions) AS impressions,
        SUM(reach) AS reach,

        CASE 
            WHEN SUM(reach) > 0 THEN SUM(impressions) / SUM(reach) 
            ELSE 0 
        END AS frequency,

        SUM(viewable_impressions) AS viewable_impressions,

        CASE 
            WHEN SUM(impressions) > 0 
            THEN SUM(viewable_impressions) / SUM(impressions) 
            ELSE 0 
        END AS viewability_rate,

        SUM(clicks) AS clicks,
        SUM(cost) AS cost,

        CASE 
            WHEN SUM(impressions) > 0 
            THEN SUM(clicks) / SUM(impressions) 
            ELSE 0 
        END AS ctr,

        CASE 
            WHEN SUM(clicks) > 0 
            THEN SUM(cost) / SUM(clicks) 
            ELSE 0 
        END AS avg_cpc,

        CASE 
            WHEN SUM(impressions) > 0 
            THEN (SUM(cost) / SUM(impressions)) * 1000 
            ELSE 0 
        END AS cpm,

        SUM(post_view_sessions) AS post_view_sessions,
        SUM(post_click_sessions) AS post_click_sessions

    FROM base
    GROUP BY
        yr,
        PACKAGE
)

SELECT * FROM monthly
UNION ALL
SELECT * FROM ytd;