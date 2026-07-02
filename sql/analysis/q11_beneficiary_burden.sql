-- ============================================================
-- Q11. Where patients (and other payers) shoulder the most
-- Business question: The gap between total payment and the
-- Medicare payment approximates deductibles, coinsurance and
-- third-party payments. Which DRGs leave the biggest gap?
-- Techniques: CTE, derived metric, volume-weighted averages
-- ============================================================

WITH drg_gap AS (
    SELECT
        drg_code,
        drg_desc,
        SUM(total_discharges)                        AS discharges,
        SUM(total_discharges * avg_total_payment)
            / NULLIF(SUM(total_discharges), 0)       AS avg_total_payment,
        SUM(total_discharges * avg_medicare_payment)
            / NULLIF(SUM(total_discharges), 0)       AS avg_medicare_payment
    FROM inpatient_charges
    GROUP BY drg_code, drg_desc
    HAVING SUM(total_discharges) >= 10000   -- common conditions only
)
SELECT
    drg_code,
    drg_desc,
    discharges,
    ROUND(avg_total_payment, 0)                       AS avg_total_payment,
    ROUND(avg_medicare_payment, 0)                    AS avg_medicare_payment,
    ROUND(avg_total_payment - avg_medicare_payment, 0) AS avg_gap_per_discharge,
    ROUND(100.0 * (avg_total_payment - avg_medicare_payment)
        / NULLIF(avg_total_payment, 0), 1)            AS gap_pct_of_payment
FROM drg_gap
ORDER BY avg_gap_per_discharge DESC
LIMIT 15;
