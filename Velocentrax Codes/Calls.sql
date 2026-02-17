-----------------------Calls---------------------------

CREATE OR REPLACE TABLE calls_omni_l1 AS

WITH base AS (
    SELECT
        DATE_TRUNC('MONTH', CONTACT_DATE) AS month_dt,
        YEAR(CONTACT_DATE) AS yr,
        TIER,
        CALL_TYPE,
        CALL_DURATION,
        INTERACTION_ID,
        CUSTOMER_ID
    FROM calls_omni
),


monthly_detail AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        TIER,
        CALL_TYPE,
        CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY month_dt, TIER, CALL_TYPE, CALL_DURATION
),


monthly_all AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        'ALL' AS TIER,
        'ALL' AS CALL_TYPE,
         null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY month_dt
),


monthly_all_1 AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        'ALL' AS TIER,
        call_type AS CALL_TYPE,
        null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY month_dt, call_type, CALL_DURATION
),

monthly_all_2 AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        tier AS TIER,
        'ALL' AS CALL_TYPE,
        null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY month_dt, tier
),

monthly_all_3 AS (
    SELECT
        'MONTH' AS time_granularity,
        month_dt AS period,
        tier AS TIER,
        call_type AS CALL_TYPE,
        null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY month_dt, tier, CALL_type
),


yearly_detail AS (
    SELECT
        'YEAR' AS time_granularity,
        NULL AS period,
        TIER,
        CALL_TYPE,
        CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY yr, TIER, CALL_TYPE, CALL_DURATION
),


yearly_all AS (
    SELECT
        'YEAR' AS time_granularity,
        NULL AS period,
        'ALL' AS TIER,
        'ALL' AS CALL_TYPE,
        null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY yr
),

yearly_all_1 AS (
    SELECT
        'YEAR' AS time_granularity,
        NULL AS period,
        'ALL' AS TIER,
        call_type AS CALL_TYPE,
        CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY yr, call_type, CALL_DURATION
),
yearly_all_2 AS (
    SELECT
        'YEAR' AS time_granularity,
        NULL AS period,
        tier AS TIER,
        'ALL' AS CALL_TYPE,
        null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY yr, tier
),
yearly_all_3 AS (
    SELECT
        'YEAR' AS time_granularity,
        NULL AS period,
        tier AS TIER,
        call_type AS CALL_TYPE,
        null as CALL_DURATION,
        COUNT(INTERACTION_ID) AS total_calls,
        COUNT(DISTINCT CUSTOMER_ID) AS reached_customers
    FROM base
    GROUP BY yr, tier, CALL_type
)

SELECT * FROM monthly_detail
UNION ALL
SELECT * FROM monthly_all
UNION all
select * from monthly_all_1
UNION ALL
select * from monthly_all_2
union all
select * from monthly_all_3
union all
SELECT * FROM yearly_detail
union all
select * from yearly_all
union all
select * from yearly_all_1
UNION ALL
SELECT * FROM yearly_all_2
union all
select * from yearly_all_3;
