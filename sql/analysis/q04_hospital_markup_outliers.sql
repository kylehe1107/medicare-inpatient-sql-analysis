-- ============================================================
-- Q4. Hospitals with extreme charge-to-payment markups
-- Business question: Which hospitals bill the most relative to
-- what they're actually paid? (Relevant to price transparency
-- and surprise-billing policy debates.)
-- Techniques: CTE, HAVING volume filter, RANK(), LEFT JOIN to dim
-- ============================================================

WITH hospital_markup AS (
    SELECT
        ic.provider_ccn,
        ic.provider_name,
        ic.provider_state,
        SUM(ic.total_discharges)                            AS discharges,
        SUM(ic.total_discharges * ic.avg_covered_charges)
            / NULLIF(SUM(ic.total_discharges * ic.avg_total_payment), 0) AS markup_ratio,
        SUM(ic.total_discharges * ic.avg_total_payment)
            / NULLIF(SUM(ic.total_discharges), 0)           AS payment_per_discharge
    FROM inpatient_charges ic
    GROUP BY ic.provider_ccn, ic.provider_name, ic.provider_state
    HAVING SUM(ic.total_discharges) >= 500   -- exclude low-volume noise
)
SELECT
    hm.provider_name,
    hm.provider_state                          AS state,
    h.hospital_ownership,
    h.overall_rating,
    hm.discharges,
    ROUND(hm.markup_ratio, 2)                  AS markup_ratio,
    ROUND(hm.payment_per_discharge, 0)         AS payment_per_discharge,
    RANK() OVER (ORDER BY hm.markup_ratio DESC) AS markup_rank
FROM hospital_markup hm
LEFT JOIN hospitals h ON h.facility_id = hm.provider_ccn
ORDER BY hm.markup_ratio DESC
LIMIT 20;
