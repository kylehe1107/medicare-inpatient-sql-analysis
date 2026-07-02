-- ============================================================
-- Q12. Do high-volume hospitals deliver cheaper care?
-- Business question: For joint replacement (DRG 470), is there
-- an economies-of-scale effect — do hospitals doing more of
-- them get paid less per case?
-- Techniques: NTILE() quartiles, CTE pipeline
-- ============================================================

WITH drg470_hospitals AS (
    SELECT
        provider_ccn,
        provider_name,
        total_discharges,
        avg_total_payment
    FROM inpatient_charges
    WHERE drg_code = '470'
      AND total_discharges >= 11   -- CMS suppresses <11; keep reliable rows
),
quartiled AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_discharges) AS volume_quartile
    FROM drg470_hospitals
)
SELECT
    volume_quartile,
    CASE volume_quartile
        WHEN 1 THEN 'Q1 - lowest volume'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4 - highest volume'
    END                                              AS quartile_label,
    COUNT(*)                                         AS hospitals,
    MIN(total_discharges)                            AS min_cases,
    MAX(total_discharges)                            AS max_cases,
    ROUND(SUM(total_discharges * avg_total_payment)
        / NULLIF(SUM(total_discharges), 0), 0)       AS payment_per_case,
    ROUND(AVG(avg_total_payment), 0)                 AS unweighted_avg_payment
FROM quartiled
GROUP BY volume_quartile
ORDER BY volume_quartile;
