---------------------------------------------------Omni L1------------------------------------------------


select * from overall_omni_l1;

CREATE OR REPLACE TABLE overall_omni_l1 AS

WITH 


all_hcp_base AS (
    SELECT DISTINCT hcp_id, month, year FROM (
        SELECT customer_id AS hcp_id,
               MONTH(TO_DATE(contact_date)) AS month,
               YEAR(TO_DATE(contact_date)) AS year
        FROM calls_omni

        UNION

        SELECT customer_id,
               MONTH(TO_DATE(email_date)),
               YEAR(TO_DATE(email_date))
        FROM email_omni

        UNION

        SELECT customer_id,
               MONTH(TO_DATE(start_time)),
               YEAR(TO_DATE(start_time))
        FROM congress_omni

        UNION

        SELECT b.id,
               MONTH(TO_DATE(a.week)),
               YEAR(TO_DATE(a.week))
        FROM mv_099_omni_trx a
        LEFT JOIN hcp_db b
            ON a.hcp_id = b.hcp_id
    )
),


calls_agg AS (
    SELECT
        customer_id AS HCP_ID,
        MONTH(TO_DATE(contact_date)) AS month,
        YEAR(TO_DATE(contact_date)) AS year,
        COUNT(DISTINCT INTERACTION_ID) AS TOTAL_CALLS
    FROM calls_omni
    GROUP BY 1,2,3
),


emails_agg AS (
    SELECT
        customer_id AS HCP_ID,
        MONTH(TO_DATE(email_date)) AS month,
        YEAR(TO_DATE(email_date)) AS year,
        SUM(CASE WHEN delivery_status = 'Delivered' THEN 1 ELSE 0 END) AS TOTAL_EMAILS_SENT,
        SUM(CASE WHEN OPENED_FLAG = 'TRUE' THEN 1 ELSE 0 END) AS TOTAL_EMAILS_OPENED,
        SUM(CASE WHEN CLICKED_FLAG = 'TRUE' THEN 1 ELSE 0 END) AS TOTAL_EMAILS_CLICKED
    FROM email_omni
    GROUP BY 1,2,3
),


congress_agg AS (
    SELECT
        customer_id AS HCP_ID,
        MONTH(TO_DATE(start_time)) AS month,
        YEAR(TO_DATE(start_time)) AS year,
        SUM(CASE WHEN invitation_sent='TRUE' THEN 1 ELSE 0 END) AS TOTAL_CONGRESS_INVITES,
        SUM(CASE WHEN registered='TRUE' THEN 1 ELSE 0 END) AS TOTAL_CONGRESS_REG,
        SUM(CASE WHEN attended='TRUE' THEN 1 ELSE 0 END) AS TOTAL_CONGRESS_ATTEND
    FROM congress_omni
    GROUP BY 1,2,3
),


trx_agg AS (
    SELECT
        b.id AS hcp_id,
        MONTH(TO_DATE(a.week)) AS month,
        YEAR(TO_DATE(a.week)) AS year,
        SUM(TRX_CNT) AS TOTAL_TRX
    FROM mv_099_omni_trx a
    LEFT JOIN hcp_db b
        ON a.hcp_id = b.hcp_id
    GROUP BY 1,2,3
)


SELECT

    a.hcp_id,
    a.month,
    a.year,
    m.hco_id,
    m.territory_id,
    m.target_type AS tier,

    /* CHANNEL METRICS */
    COALESCE(c.total_calls,0) AS total_calls,
    COALESCE(e.total_emails_sent,0) AS total_emails_sent,
    COALESCE(e.total_emails_opened,0) AS total_emails_opened,
    COALESCE(e.total_emails_clicked,0) AS total_emails_clicked,
    COALESCE(g.total_congress_invites,0) AS total_congress_invites,
    COALESCE(g.total_congress_reg,0) AS total_congress_reg,
    COALESCE(g.total_congress_attend,0) AS total_congress_attend,
    COALESCE(t.total_trx,0) AS total_trx,

    

    /* CALLS */
    CASE WHEN COALESCE(c.total_calls,0) > 0 THEN 1 ELSE 0 END AS calls_reach_flag,
    CASE WHEN COALESCE(c.total_calls,0) > 0 THEN 1 ELSE 0 END AS calls_engagement_flag,
    CASE WHEN COALESCE(c.total_calls,0) > 0 THEN 1 ELSE 0 END AS calls_deep_engagement_flag,

    /* EMAIL */
    CASE WHEN COALESCE(e.total_emails_sent,0) > 0 THEN 1 ELSE 0 END AS email_reach_flag,
    CASE WHEN COALESCE(e.total_emails_opened,0) > 0 THEN 1 ELSE 0 END AS email_engagement_flag,
    CASE WHEN COALESCE(e.total_emails_clicked,0) > 0 THEN 1 ELSE 0 END AS email_deep_engagement_flag,

    /* CONGRESS */
    CASE WHEN COALESCE(g.total_congress_invites,0) > 0 THEN 1 ELSE 0 END AS congress_reach_flag,
    CASE WHEN COALESCE(g.total_congress_reg,0) > 0 THEN 1 ELSE 0 END AS congress_engagement_flag,
    CASE WHEN COALESCE(g.total_congress_attend,0) > 0 THEN 1 ELSE 0 END AS congress_deep_engagement_flag,

   

    /* REACH = Any contact */
    CASE 
        WHEN COALESCE(c.total_calls,0) > 0
          OR COALESCE(e.total_emails_sent,0) > 0
          OR COALESCE(g.total_congress_invites,0) > 0
        THEN 1 ELSE 0
    END AS overall_reach_flag,

    /* ENGAGEMENT = Open or Registration */
    CASE 
        WHEN COALESCE(c.total_calls,0) > 0 or 
        COALESCE(e.total_emails_opened,0) > 0
          OR COALESCE(g.total_congress_reg,0) > 0
        THEN 1 ELSE 0
    END AS overall_engagement_flag,

    /* DEEP ENGAGEMENT = Click or Attendance */
    CASE 
        WHEN COALESCE(c.total_calls,0) > 0 or COALESCE(e.total_emails_clicked,0) > 0
          OR COALESCE(g.total_congress_attend,0) > 0
        THEN 1 ELSE 0
    END AS overall_deep_engagement_flag

FROM all_hcp_base a
LEFT JOIN hcp_db m
    ON a.hcp_id = m.id
LEFT JOIN calls_agg c
    ON a.hcp_id = c.hcp_id
   AND a.month = c.month
   AND a.year = c.year
LEFT JOIN emails_agg e
    ON a.hcp_id = e.hcp_id
   AND a.month = e.month
   AND a.year = e.year
LEFT JOIN congress_agg g
    ON a.hcp_id = g.hcp_id
   AND a.month = g.month
   AND a.year = g.year
LEFT JOIN trx_agg t
    ON a.hcp_id = t.hcp_id
   AND a.month = t.month
   AND a.year = t.year
   WHERE
    (
        COALESCE(c.total_calls,0)
      + COALESCE(e.total_emails_sent,0)
      + COALESCE(g.total_congress_invites,0)
    ) > 0
    OR COALESCE(t.total_trx,0) > 0;


----------------Omni L2--------------------------

select * from overall_omni_l2;

CREATE OR REPLACE TABLE overall_omni_l2 AS

WITH base AS (
    SELECT *
    FROM overall_omni_l1
),


channel_base AS (

    SELECT
        month,
        year,
        tier AS target_type,
        'Calls' AS channel,
        hcp_id,
        calls_reach_flag AS reach_flag,
        calls_engagement_flag AS engagement_flag,
        calls_deep_engagement_flag AS deep_engagement_flag,
        total_calls AS channel_volume,
        total_trx
    FROM base

    UNION ALL

    SELECT
        month,
        year,
        tier,
        'Emails',
        hcp_id,
        email_reach_flag,
        email_engagement_flag,
        email_deep_engagement_flag,
        total_emails_sent,
        total_trx
    FROM base

    UNION ALL

    SELECT
        month,
        year,
        tier,
        'Congress',
        hcp_id,
        congress_reach_flag,
        congress_engagement_flag,
        congress_deep_engagement_flag,
        total_congress_invites,
        total_trx
    FROM base
),


overall_channel AS (
    SELECT
        month,
        year,
        tier AS target_type,
        'OVERALL' AS channel,
        hcp_id,
        overall_reach_flag AS reach_flag,
        overall_engagement_flag AS engagement_flag,
        overall_deep_engagement_flag AS deep_engagement_flag,
        (COALESCE(total_calls,0)
         + COALESCE(total_emails_sent,0)
         + COALESCE(total_congress_invites,0)) AS channel_volume,
        total_trx
    FROM base
),

full_channel_base AS (
    SELECT * FROM channel_base
    UNION ALL
    SELECT * FROM overall_channel
),


monthly_agg AS (
    SELECT
        'MONTHLY' AS time_granularity,
        month,
        year,
        target_type,
        channel,

        COUNT(DISTINCT CASE WHEN reach_flag = 1 THEN hcp_id END) AS reached_hcps,
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 THEN hcp_id END) AS engaged_hcps,
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 THEN hcp_id END) AS deep_engaged_hcps,

        COUNT(DISTINCT CASE WHEN total_trx > 0 THEN hcp_id END) AS total_writers,
        COUNT(DISTINCT CASE WHEN reach_flag = 1 AND total_trx > 0 THEN hcp_id END) AS writers_reached,
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 AND total_trx > 0 THEN hcp_id END) AS writers_engaged,
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 AND total_trx > 0 THEN hcp_id END) AS writers_deep_engaged,

        SUM(total_trx) AS total_trx,
        SUM(CASE WHEN reach_flag = 1 THEN total_trx ELSE 0 END) AS trx_from_reached,
        SUM(CASE WHEN engagement_flag = 1 THEN total_trx ELSE 0 END) AS trx_from_engaged,
        SUM(CASE WHEN deep_engagement_flag = 1 THEN total_trx ELSE 0 END) AS trx_from_deep_engaged,

        SUM(channel_volume) AS total_channel_volume

    FROM full_channel_base
    GROUP BY 1,2,3,4,5
),


monthly_all_target AS (
    SELECT
        'MONTHLY',
        month,
        year,
        'ALL' AS target_type,
        channel,

        COUNT(DISTINCT CASE WHEN reach_flag = 1 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 THEN hcp_id END),

        COUNT(DISTINCT CASE WHEN total_trx > 0 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN reach_flag = 1 AND total_trx > 0 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 AND total_trx > 0 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 AND total_trx > 0 THEN hcp_id END),

        SUM(total_trx),
        SUM(CASE WHEN reach_flag = 1 THEN total_trx ELSE 0 END),
        SUM(CASE WHEN engagement_flag = 1 THEN total_trx ELSE 0 END),
        SUM(CASE WHEN deep_engagement_flag = 1 THEN total_trx ELSE 0 END),

        SUM(channel_volume)

    FROM full_channel_base
    GROUP BY 2,3,5
),


yearly_agg AS (
    SELECT
        'YEARLY',
        NULL AS month,
        year,
        target_type,
        channel,

        COUNT(DISTINCT CASE WHEN reach_flag = 1 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 THEN hcp_id END),

        COUNT(DISTINCT CASE WHEN total_trx > 0 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN reach_flag = 1 AND total_trx > 0 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 AND total_trx > 0 THEN hcp_id END),
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 AND total_trx > 0 THEN hcp_id END),

        SUM(total_trx),
        SUM(CASE WHEN reach_flag = 1 THEN total_trx ELSE 0 END),
        SUM(CASE WHEN engagement_flag = 1 THEN total_trx ELSE 0 END),
        SUM(CASE WHEN deep_engagement_flag = 1 THEN total_trx ELSE 0 END),

        SUM(channel_volume)

    FROM full_channel_base
    GROUP BY 3,4,5
),


yearly_all_target AS (
    SELECT
        'YEARLY' AS time_granularity,
        NULL AS month,
        year,
        'ALL' AS target_type,
        channel,

        COUNT(DISTINCT CASE WHEN reach_flag = 1 THEN hcp_id END) AS reached_hcps,
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 THEN hcp_id END) AS engaged_hcps,
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 THEN hcp_id END) AS deep_engaged_hcps,

        COUNT(DISTINCT CASE WHEN total_trx > 0 THEN hcp_id END) AS total_writers,
        COUNT(DISTINCT CASE WHEN reach_flag = 1 AND total_trx > 0 THEN hcp_id END) AS writers_reached,
        COUNT(DISTINCT CASE WHEN engagement_flag = 1 AND total_trx > 0 THEN hcp_id END) AS writers_engaged,
        COUNT(DISTINCT CASE WHEN deep_engagement_flag = 1 AND total_trx > 0 THEN hcp_id END) AS writers_deep_engaged,

        SUM(total_trx) AS total_trx,
        SUM(CASE WHEN reach_flag = 1 THEN total_trx ELSE 0 END) AS trx_from_reached,
        SUM(CASE WHEN engagement_flag = 1 THEN total_trx ELSE 0 END) AS trx_from_engaged,
        SUM(CASE WHEN deep_engagement_flag = 1 THEN total_trx ELSE 0 END) AS trx_from_deep_engaged,

        SUM(channel_volume) AS total_channel_volume

    FROM full_channel_base
    GROUP BY year, channel
)


SELECT
    time_granularity,
    month,
    year,
    target_type,
    channel,

    reached_hcps,
    engaged_hcps,
    deep_engaged_hcps,

    total_writers,
    writers_reached,
    writers_engaged,
    writers_deep_engaged,

    total_trx,
    trx_from_reached,
    trx_from_engaged,
    trx_from_deep_engaged,

    CASE 
        WHEN reached_hcps > 0
        THEN total_channel_volume / reached_hcps
        ELSE 0
    END AS reach_frequency

FROM (
    SELECT * FROM monthly_agg
    UNION ALL
    SELECT * FROM monthly_all_target
    UNION ALL
    SELECT * FROM yearly_agg
    UNION ALL
    SELECT * FROM yearly_all_target
);
