-- ============================================================
-- Q6. Cost & billing behavior by hospital ownership type
-- Business question: Do for-profit hospitals bill or get paid
-- differently than non-profit and government hospitals?
-- Techniques: INNER JOIN fact->dim, grouped weighted averages
-- ============================================================

SELECT
    h.hospital_ownership,
    COUNT(DISTINCT ic.provider_ccn)                     AS hospitals,
    SUM(ic.total_discharges)                            AS discharges,
    ROUND(SUM(ic.total_discharges * ic.avg_covered_charges)
        / NULLIF(SUM(ic.total_discharges), 0), 0)       AS avg_charge_per_discharge,
    ROUND(SUM(ic.total_discharges * ic.avg_total_payment)
        / NULLIF(SUM(ic.total_discharges), 0), 0)       AS avg_payment_per_discharge,
    ROUND(SUM(ic.total_discharges * ic.avg_covered_charges)
        / NULLIF(SUM(ic.total_discharges * ic.avg_total_payment), 0), 2) AS markup_ratio,
    ROUND(AVG(h.overall_rating), 2)                     AS avg_star_rating
FROM inpatient_charges ic
JOIN hospitals h ON h.facility_id = ic.provider_ccn
GROUP BY h.hospital_ownership
HAVING COUNT(DISTINCT ic.provider_ccn) >= 25
ORDER BY markup_ratio DESC;
