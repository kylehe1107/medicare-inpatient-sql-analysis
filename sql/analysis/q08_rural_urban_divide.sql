-- ============================================================
-- Q8. Rural vs urban: access and cost divide
-- Business question: How do discharge volumes and payments
-- differ between metropolitan, micropolitan and rural hospitals?
-- Techniques: CASE bucketing on RUCA codes, grouped aggregates
-- ============================================================

WITH classified AS (
    SELECT
        CASE
            WHEN ruca_code IN ('1', '2', '3')            THEN '1. Metropolitan'
            WHEN ruca_code IN ('4', '5', '6')            THEN '2. Micropolitan'
            WHEN ruca_code IN ('7', '8', '9')            THEN '3. Small town'
            WHEN ruca_code = '10'                        THEN '4. Rural'
            ELSE '5. Unknown'
        END AS area_type,
        provider_ccn,
        total_discharges,
        avg_covered_charges,
        avg_total_payment,
        avg_medicare_payment
    FROM inpatient_charges
)
SELECT
    area_type,
    COUNT(DISTINCT provider_ccn)                        AS hospitals,
    SUM(total_discharges)                               AS discharges,
    ROUND(SUM(total_discharges * avg_total_payment)
        / NULLIF(SUM(total_discharges), 0), 0)          AS payment_per_discharge,
    ROUND(SUM(total_discharges * avg_covered_charges)
        / NULLIF(SUM(total_discharges * avg_total_payment), 0), 2) AS markup_ratio,
    ROUND(100.0 * SUM(total_discharges)
        / SUM(SUM(total_discharges)) OVER (), 1)        AS pct_of_national_volume
FROM classified
GROUP BY area_type
ORDER BY area_type;
