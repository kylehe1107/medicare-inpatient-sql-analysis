-- ============================================================
-- Q10. Hospital market concentration by state
-- Business question: In which states is Medicare inpatient
-- volume concentrated in just a few hospitals? (Proxy for
-- market power / access risk.)
-- Techniques: nested CTEs, ROW_NUMBER(), conditional aggregation
-- ============================================================

WITH hospital_volume AS (
    SELECT
        provider_state                       AS state,
        provider_ccn,
        SUM(total_discharges)                AS discharges
    FROM inpatient_charges
    GROUP BY provider_state, provider_ccn
),
ranked AS (
    SELECT
        state,
        provider_ccn,
        discharges,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY discharges DESC) AS hosp_rank
    FROM hospital_volume
)
SELECT
    state,
    COUNT(*)                                                  AS hospitals,
    SUM(discharges)::bigint                                   AS total_discharges,
    ROUND(100.0 * SUM(CASE WHEN hosp_rank <= 3 THEN discharges ELSE 0 END)
        / NULLIF(SUM(discharges), 0), 1)                      AS top3_share_pct,
    ROUND(100.0 * SUM(CASE WHEN hosp_rank <= 10 THEN discharges ELSE 0 END)
        / NULLIF(SUM(discharges), 0), 1)                      AS top10_share_pct
FROM ranked
GROUP BY state
HAVING COUNT(*) >= 5
ORDER BY top3_share_pct DESC;
