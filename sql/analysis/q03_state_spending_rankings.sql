-- ============================================================
-- Q3. State-level cost rankings
-- Business question: Where is Medicare inpatient care most
-- expensive per discharge, and which states drive total spend?
-- Techniques: CTE, RANK() window functions, weighted averages
-- ============================================================

WITH state_stats AS (
    SELECT
        provider_state                                  AS state,
        COUNT(DISTINCT provider_ccn)                    AS hospitals,
        SUM(total_discharges)                           AS discharges,
        SUM(total_discharges * avg_medicare_payment)    AS medicare_spend,
        SUM(total_discharges * avg_total_payment)
            / NULLIF(SUM(total_discharges), 0)          AS payment_per_discharge,
        SUM(total_discharges * avg_covered_charges)
            / NULLIF(SUM(total_discharges * avg_total_payment), 0) AS markup_ratio
    FROM inpatient_charges
    GROUP BY provider_state
)
SELECT
    state,
    hospitals,
    discharges,
    ROUND(medicare_spend / 1e9, 2)            AS medicare_spend_usd_bn,
    ROUND(payment_per_discharge, 0)           AS payment_per_discharge,
    ROUND(markup_ratio, 2)                    AS markup_ratio,
    RANK() OVER (ORDER BY payment_per_discharge DESC) AS cost_rank,
    RANK() OVER (ORDER BY medicare_spend DESC)        AS spend_rank
FROM state_stats
ORDER BY payment_per_discharge DESC;
