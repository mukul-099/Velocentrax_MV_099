----------------------TRx Data--------------------------

Select * from mv_099_omni_trx;

select * from mv_099_omni_trx_l1;

CREATE OR REPLACE TABLE mv_099_omni_trx_l1 AS

WITH base AS (
    SELECT
        month(to_date(week)) AS MONTH_DATE,
        year(to_date(WEEK))                AS YEAR_NUM,
        DRUG_CLASS,
        TRX_CNT,
        TRX_QTY
    FROM mv_099_omni_trx
)



SELECT
    'MONTHLY' AS GRANULARITY,
    MONTH_DATE AS PERIOD,
    'ALL' AS SUB_GRANULARITY,
    'ALL' AS SUB_GRANULARITY_VALUE,

    SUM(TRX_CNT) AS TOTAL_TRX_CNT,
    SUM(TRX_QTY) AS TOTAL_TRX_QTY

FROM base
GROUP BY 1,2,3,4

UNION ALL



SELECT
    'MONTHLY',
    MONTH_DATE,
    'DRUG_CLASS',
    DRUG_CLASS,

    SUM(TRX_CNT),
    SUM(TRX_QTY)

FROM base
GROUP BY 1,2,3,4




UNION ALL



SELECT
    'YEARLY',
    YEAR_NUM,
    'ALL',
    'ALL',

    SUM(TRX_CNT),
    SUM(TRX_QTY)

FROM base
GROUP BY 1,2,3,4

UNION ALL



SELECT
    'YEARLY',
    YEAR_NUM,
    'DRUG_CLASS',
    DRUG_CLASS,

    SUM(TRX_CNT),
    SUM(TRX_QTY)

FROM base
GROUP BY 1,2,3,4
;


----------HCP Writing Analysis--------------

select * from mv_099_hcp_analysis;

CREATE OR REPLACE TABLE mv_099_hcp_analysis AS

WITH base AS (
    SELECT
        a.HCP_ID,
        b.id,
        a.WEEK,
        a.TRX_CNT
    FROM mv_099_omni_trx a left join hcp_db b on a.hcp_id=b.hcp_id
),

hcp_summary AS (
    SELECT
        id,
        HCP_ID,
        MIN(WEEK) AS FIRST_WEEK,
        MAX(WEEK) AS LAST_WEEK,
        COUNT(DISTINCT WEEK) AS TOTAL_WEEKS_ACTIVE,
        SUM(TRX_CNT) AS TOTAL_TRX,
        AVG(TRX_CNT) AS AVG_WEEKLY_TRX
    FROM base
    GROUP BY HCP_ID, id
),

year_bounds AS (
    SELECT
        MIN(WEEK) AS YEAR_START,
        MAX(WEEK) AS YEAR_END
    FROM base
)

SELECT
    h.id,
    h.HCP_ID,
    h.FIRST_WEEK,
    h.LAST_WEEK,
    h.TOTAL_WEEKS_ACTIVE,
    h.TOTAL_TRX,
    ROUND(h.AVG_WEEKLY_TRX,2) AS AVG_WEEKLY_TRX,

   

    CASE
        WHEN h.FIRST_WEEK <= DATE '2025-02-03'
             AND h.LAST_WEEK >= DATE '2025-12-01'
             AND h.TOTAL_WEEKS_ACTIVE > 35
            THEN 'CONSISTENT'

        WHEN h.FIRST_WEEK <= DATE '2025-03-01'
             AND h.LAST_WEEK < DATE '2025-08-01'
            THEN 'DROP_OFF'

        WHEN h.FIRST_WEEK > DATE '2025-05-01'
            THEN 'LATE_ADOPTER'

        ELSE 'INTERMITTENT'
    END AS WRITING_PATTERN,

    

    CASE
        WHEN h.TOTAL_TRX >= 400 THEN 'HIGH'
        WHEN h.TOTAL_TRX >= 150 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS VOLUME_SEGMENT

FROM hcp_summary h;


-----------HCP TRX Analysis------

---Base---

select * from mv_099_base;

CREATE OR REPLACE TABLE mv_099_base AS
SELECT
    t.HCP_ID,
    t.TERRITORY_ID,
    m.target_type AS TIER,
    t.WEEK,
    DATE_TRUNC('MONTH', t.WEEK) AS MONTH_DATE,
    YEAR(t.WEEK) AS YEAR_NUM,
    t.TRX_CNT
FROM mv_099_omni_trx t
LEFT JOIN hcp_db m
    ON t.HCP_ID = m.HCP_ID;

---HCP Summary---

select * from mv_099_hcp_summary;

CREATE OR REPLACE TABLE mv_099_hcp_summary AS
SELECT
    HCP_ID,
    MIN(WEEK) AS FIRST_WEEK,
    MAX(WEEK) AS LAST_WEEK,
    COUNT(DISTINCT WEEK) AS WEEKS_ACTIVE,
    SUM(TRX_CNT) AS TOTAL_TRX,
    AVG(TRX_CNT) AS AVG_TRX
FROM mv_099_base
GROUP BY HCP_ID;

-----Monthly HCP Retentions-----

select * from mv_099_monthly_retention;

CREATE OR REPLACE TABLE mv_099_monthly_retention AS
SELECT
    MONTH_DATE,
    COUNT(DISTINCT HCP_ID) AS ACTIVE_HCPS
FROM mv_099_base
GROUP BY MONTH_DATE
ORDER BY MONTH_DATE;

---------Cohort Analysis---------

Select * from mv_099_cohort_analysis;

CREATE OR REPLACE TABLE mv_099_cohort_analysis AS
SELECT
    DATE_TRUNC('MONTH', FIRST_WEEK) AS COHORT_MONTH,
    COUNT(*) AS HCP_COUNT,
    SUM(TOTAL_TRX) AS COHORT_TOTAL_TRX
FROM mv_099_hcp_summary
GROUP BY 1
ORDER BY 1;


------Tier Vs Behaviour Matrix -----

---Behaviour--

select * from mv_099_hcp_behavior;

CREATE OR REPLACE TABLE mv_099_hcp_behavior AS
SELECT
    s.*,
    b.TIER,
    CASE
        WHEN WEEKS_ACTIVE >= 35 THEN 'CONSISTENT'
        WHEN WEEKS_ACTIVE BETWEEN 15 AND 34 THEN 'MODERATE'
        ELSE 'LOW_ACTIVITY'
    END AS WRITING_PATTERN,
    CASE
        WHEN TOTAL_TRX >= 400 THEN 'HIGH'
        WHEN TOTAL_TRX >= 150 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS VALUE_SEGMENT
FROM mv_099_hcp_summary s
LEFT JOIN (
    SELECT DISTINCT HCP_ID, TIER
    FROM mv_099_base
) b
ON s.HCP_ID = b.HCP_ID;

---Matrix---

select * from mv_099_tier_behavior_matrix;

CREATE OR REPLACE TABLE mv_099_tier_behavior_matrix AS
SELECT
    TIER,
    WRITING_PATTERN,
    COUNT(*) AS HCP_COUNT,
    SUM(TOTAL_TRX) AS TOTAL_TRX
FROM mv_099_hcp_behavior
GROUP BY 1,2
ORDER BY 1,2;

-----------------Territory Level Adoption Ranking --------------

select * from mv_099_territory_ranking;

CREATE OR REPLACE TABLE mv_099_territory_ranking AS
SELECT
    TERRITORY_ID,
    COUNT(DISTINCT HCP_ID) AS WRITING_HCPS,
    SUM(TRX_CNT) AS TOTAL_TRX,
    RANK() OVER (ORDER BY SUM(TRX_CNT) DESC) AS TERRITORY_RANK
FROM mv_099_base
GROUP BY TERRITORY_ID;

-------------Growth Funnel ------------

select * from mv_099_growth_funnel;

CREATE OR REPLACE TABLE mv_099_growth_funnel AS
SELECT
    COUNT(DISTINCT HCP_ID) AS TOTAL_WRITERS,
    COUNT(DISTINCT CASE WHEN WEEKS_ACTIVE >= 4 THEN HCP_ID END) AS ACTIVE_HCPS,
    COUNT(DISTINCT CASE WHEN TOTAL_TRX >= 400 THEN HCP_ID END) AS HIGH_VALUE_HCPS
FROM mv_099_hcp_summary;

-----------------------------------------------------------------------------------------------------------------------------------

----------------HCO Analysis------------------

select * from mv_099_hco_base;

CREATE OR REPLACE TABLE mv_099_hco_base AS
SELECT
    b.HCP_ID,
    m.HCO_ID,
    b.TERRITORY_ID,
    b.WEEK,
    b.MONTH_DATE,
    b.TRX_CNT
FROM mv_099_base b
LEFT JOIN hcp_db m
    ON b.HCP_ID = m.HCP_ID
WHERE m.HCO_ID IS NOT NULL;

---------HCO Summary---------

select * from mv_099_hco_summary;

CREATE OR REPLACE TABLE mv_099_hco_summary AS
SELECT
    HCO_ID,
    COUNT(DISTINCT HCP_ID) AS LINKED_HCPS,
    COUNT(DISTINCT TERRITORY_ID) AS TERRITORY_SPREAD,
    SUM(TRX_CNT) AS TOTAL_TRX,
    AVG(TRX_CNT) AS AVG_WEEKLY_TRX,
    COUNT(DISTINCT WEEK) AS ACTIVE_WEEKS
FROM mv_099_hco_base
GROUP BY HCO_ID;

----------High Value HCOs-------

select * from mv_099_high_value_hco;

CREATE OR REPLACE TABLE mv_099_high_value_hco AS
WITH threshold AS (
    SELECT
        PERCENTILE_CONT(0.75) 
        WITHIN GROUP (ORDER BY TOTAL_TRX) AS trx_cutoff
    FROM mv_099_hco_summary
)
SELECT
    s.*,
    CASE 
        WHEN s.TOTAL_TRX >= t.trx_cutoff THEN 'HIGH_VALUE'
        ELSE 'NORMAL'
    END AS HCO_SEGMENT
FROM mv_099_hco_summary s
CROSS JOIN threshold t;

------------------Volume Concentration-----------

select * from mv_099_hco_concentration;

CREATE OR REPLACE TABLE mv_099_hco_concentration AS
SELECT
    HCO_SEGMENT,
    COUNT(*) AS HCO_COUNT,
    SUM(TOTAL_TRX) AS SEGMENT_TRX,
    SUM(TOTAL_TRX) / SUM(SUM(TOTAL_TRX)) OVER () AS TRX_SHARE
FROM mv_099_high_value_hco
GROUP BY HCO_SEGMENT;

------------------High Value HCO Territory Impact---------------

select * from mv_099_high_value_hco_territory;

CREATE OR REPLACE TABLE mv_099_high_value_hco_territory AS
SELECT
    b.TERRITORY_ID,
    COUNT(DISTINCT b.HCO_ID) AS HIGH_VALUE_HCO_COUNT,
    SUM(b.TRX_CNT) AS TOTAL_TRX
FROM mv_099_hco_base b
JOIN mv_099_high_value_hco h
    ON b.HCO_ID = h.HCO_ID
WHERE h.HCO_SEGMENT = 'HIGH_VALUE'
GROUP BY b.TERRITORY_ID
ORDER BY TOTAL_TRX DESC;

------------Dependecy Risk-------------

select * from mv_099_dependency_risk;

CREATE OR REPLACE TABLE mv_099_dependency_risk AS
WITH territory_total AS (
    SELECT
        TERRITORY_ID,
        SUM(TRX_CNT) AS TOTAL_TRX
    FROM mv_099_base
    GROUP BY TERRITORY_ID
),
territory_hco AS (
    SELECT
        b.TERRITORY_ID,
        SUM(b.TRX_CNT) AS HCO_TRX
    FROM mv_099_hco_base b
    JOIN mv_099_high_value_hco h
        ON b.HCO_ID = h.HCO_ID
    WHERE h.HCO_SEGMENT = 'HIGH_VALUE'
    GROUP BY b.TERRITORY_ID
)
SELECT
    t.TERRITORY_ID,
    t.HCO_TRX,
    tt.TOTAL_TRX,
    t.HCO_TRX / tt.TOTAL_TRX AS DEPENDENCY_RATIO,
    CASE
        WHEN t.HCO_TRX / tt.TOTAL_TRX > 0.6 THEN 'HIGH_DEPENDENCY'
        WHEN t.HCO_TRX / tt.TOTAL_TRX > 0.3 THEN 'MEDIUM_DEPENDENCY'
        ELSE 'LOW_DEPENDENCY'
    END AS RISK_FLAG
FROM territory_hco t
JOIN territory_total tt
    ON t.TERRITORY_ID = tt.TERRITORY_ID;