-- ============================================================
-- Q7. Does higher quality cost more? Star rating vs price
-- Business question: Are higher-rated hospitals more expensive
-- per discharge? Controls for procedure mix by comparing within
-- DRG 470 (joint replacement) as well as overall.
-- Techniques: JOIN, FILTER clause (conditional aggregation)
-- ============================================================

SELECT
    h.overall_rating                                    AS star_rating,
    COUNT(DISTINCT ic.provider_ccn)                     AS hospitals,
    SUM(ic.total_discharges)                            AS discharges,
    -- overall payment per discharge (all DRGs)
    ROUND(SUM(ic.total_discharges * ic.avg_total_payment)
        / NULLIF(SUM(ic.total_discharges), 0), 0)       AS payment_per_discharge_all,
    -- apples-to-apples: joint replacement only
    ROUND(SUM(ic.total_discharges * ic.avg_total_payment)
              FILTER (WHERE ic.drg_code = '470')
        / NULLIF(SUM(ic.total_discharges)
              FILTER (WHERE ic.drg_code = '470'), 0), 0) AS payment_per_discharge_drg470,
    ROUND(SUM(ic.total_discharges * ic.avg_covered_charges)
        / NULLIF(SUM(ic.total_discharges * ic.avg_total_payment), 0), 2) AS markup_ratio
FROM inpatient_charges ic
JOIN hospitals h ON h.facility_id = ic.provider_ccn
WHERE h.overall_rating IS NOT NULL
GROUP BY h.overall_rating
ORDER BY h.overall_rating;
