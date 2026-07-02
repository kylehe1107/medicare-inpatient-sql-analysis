-- ============================================================
-- Q9. The most common inpatient diagnosis in each state
-- Business question: What does each state's Medicare population
-- get hospitalized for the most (beyond the national #1)?
-- Techniques: two-level CTE, ROW_NUMBER() OVER (PARTITION BY)
-- ============================================================

WITH state_drg AS (
    SELECT
        provider_state                             AS state,
        drg_code,
        drg_desc,
        SUM(total_discharges)                      AS discharges
    FROM inpatient_charges
    GROUP BY provider_state, drg_code, drg_desc
),
ranked AS (
    SELECT
        state,
        drg_code,
        drg_desc,
        discharges,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY discharges DESC) AS rn,
        ROUND(100.0 * discharges
            / SUM(discharges) OVER (PARTITION BY state), 1)             AS pct_of_state_volume
    FROM state_drg
)
SELECT
    state,
    drg_code,
    drg_desc  AS top_drg,
    discharges,
    pct_of_state_volume
FROM ranked
WHERE rn = 1
ORDER BY discharges DESC;
