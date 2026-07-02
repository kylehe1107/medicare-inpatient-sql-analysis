-- ============================================================
-- Q5. Price variation for the same procedure (DRG 470:
-- major hip/knee joint replacement, the highest-volume DRG)
-- Business question: How much does the price of an identical,
-- standardized procedure vary across states?
-- Techniques: CTE, weighted average, min/max spread ratio
-- ============================================================

WITH drg470 AS (
    SELECT
        provider_state                               AS state,
        COUNT(*)                                     AS hospitals,
        SUM(total_discharges)                        AS discharges,
        SUM(total_discharges * avg_total_payment)
            / NULLIF(SUM(total_discharges), 0)       AS avg_payment,
        MIN(avg_total_payment)                       AS cheapest_hospital,
        MAX(avg_total_payment)                       AS priciest_hospital
    FROM inpatient_charges
    WHERE drg_code = '470'
    GROUP BY provider_state
    HAVING COUNT(*) >= 5    -- need enough hospitals for a fair spread
)
SELECT
    state,
    hospitals,
    discharges,
    ROUND(avg_payment, 0)                            AS avg_payment,
    ROUND(cheapest_hospital, 0)                      AS cheapest_hospital,
    ROUND(priciest_hospital, 0)                      AS priciest_hospital,
    ROUND(priciest_hospital / NULLIF(cheapest_hospital, 0), 1) AS within_state_spread_x,
    RANK() OVER (ORDER BY avg_payment DESC)          AS cost_rank
FROM drg470
ORDER BY avg_payment DESC;
