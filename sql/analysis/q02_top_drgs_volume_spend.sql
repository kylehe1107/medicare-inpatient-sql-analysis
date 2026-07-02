-- ============================================================
-- Q2. Top 15 DRGs by Medicare spend (with share of total)
-- Business question: Which conditions/procedures drive the most
-- Medicare inpatient spending, and how concentrated is it?
-- Techniques: CTE, window function (SUM OVER ()), running total
-- ============================================================

WITH drg_totals AS (
    SELECT
        drg_code,
        drg_desc,
        SUM(total_discharges)                          AS discharges,
        SUM(total_discharges * avg_medicare_payment)   AS medicare_spend,
        SUM(total_discharges * avg_total_payment)
            / NULLIF(SUM(total_discharges), 0)         AS avg_payment_per_discharge
    FROM inpatient_charges
    GROUP BY drg_code, drg_desc
)
SELECT
    drg_code,
    drg_desc,
    discharges,
    ROUND(medicare_spend / 1e9, 2)                               AS medicare_spend_usd_bn,
    ROUND(avg_payment_per_discharge, 0)                          AS avg_payment_per_discharge,
    ROUND(100.0 * medicare_spend / SUM(medicare_spend) OVER (), 1) AS pct_of_total_spend,
    ROUND(100.0 * SUM(medicare_spend) OVER (ORDER BY medicare_spend DESC)
        / SUM(medicare_spend) OVER (), 1)                        AS cumulative_pct
FROM drg_totals
ORDER BY medicare_spend DESC
LIMIT 15;
