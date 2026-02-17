-----------------------------Website----------------------------

CREATE OR REPLACE TABLE website_omni_l1 AS

WITH base AS (
    SELECT
        TO_DATE(MONTH, 'YYYY-MM') AS month_dt,
        YEAR(TO_DATE(MONTH, 'YYYY-MM')) AS yr,
        SOURCE,

        SUM(SESSIONS) AS sessions,
        SUM(ENGAGED_SESSIONS) AS engaged_sessions,
        SUM(PAGEVIEWS) AS pageviews,
        SUM(EVENT_CLICKS) AS event_clicks,
        SUM(EVENT_FORM_SUBMIT) AS event_form_submit,
        SUM(EVENT_DOWNLOADS) AS event_downloads,
        SUM(EVENT_REGISTRATIONS) AS event_registrations,
        SUM(SCROLL_25) AS scroll_25,
        SUM(SCROLL_50) AS scroll_50,
        SUM(SCROLL_75) AS scroll_75,
        SUM(SCROLL_100) AS scroll_100

    FROM website_omni
    GROUP BY
        TO_DATE(MONTH, 'YYYY-MM'),
        YEAR(TO_DATE(MONTH, 'YYYY-MM')),
        SOURCE
),

monthly AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        SOURCE,

        sessions,
        engaged_sessions,
        pageviews,
        event_clicks,
        event_form_submit,
        event_downloads,
        event_registrations,
        scroll_25,
        scroll_50,
        scroll_75,
        scroll_100
    FROM base
),

ytd AS (
    SELECT
        'YTD' AS time_granularity,
        null AS period,
        SOURCE,

        SUM(sessions) AS sessions,
        SUM(engaged_sessions) AS engaged_sessions,
        SUM(pageviews) AS pageviews,
        SUM(event_clicks) AS event_clicks,
        SUM(event_form_submit) AS event_form_submit,
        SUM(event_downloads) AS event_downloads,
        SUM(event_registrations) AS event_registrations,
        SUM(scroll_25) AS scroll_25,
        SUM(scroll_50) AS scroll_50,
        SUM(scroll_75) AS scroll_75,
        SUM(scroll_100) AS scroll_100

    FROM base
    GROUP BY
        yr,
        SOURCE
)

SELECT * FROM monthly
UNION ALL
SELECT * FROM ytd;
