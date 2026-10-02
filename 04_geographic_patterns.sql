-- ============================================================
-- Query 4: Geographic Patterns
-- Answers: state/city transaction density, failure rate,
-- and revenue distribution across geography
-- ============================================================
USE upi_insights;

-- 4a. State-level summary
CREATE OR REPLACE VIEW vw_state_summary AS
SELECT
    state,
    COUNT(*)                                             AS total_transactions,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2)      AS failure_rate_pct,
    ROUND(SUM(CASE WHEN status='Success' THEN amount ELSE 0 END), 2) AS revenue,
    ROUND(AVG(amount), 2)                                 AS avg_ticket_size
FROM upi_transactions
GROUP BY state
ORDER BY total_transactions DESC;

-- 4b. City-level summary (min volume filter to avoid noisy small-sample cities)
CREATE OR REPLACE VIEW vw_city_summary AS
SELECT
    city, state,
    COUNT(*)                                             AS total_transactions,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2)      AS failure_rate_pct,
    ROUND(SUM(CASE WHEN status='Success' THEN amount ELSE 0 END), 2) AS revenue
FROM upi_transactions
GROUP BY city, state
HAVING COUNT(*) >= 200
ORDER BY total_transactions DESC;

-- 4c. State x transaction-type mix (P2P vs P2M share per state)
CREATE OR REPLACE VIEW vw_state_txn_type_mix AS
SELECT
    state,
    SUM(transaction_type='P2P')                          AS p2p_count,
    SUM(transaction_type='P2M')                          AS p2m_count,
    ROUND(SUM(transaction_type='P2M') / COUNT(*) * 100, 2) AS p2m_share_pct
FROM upi_transactions
GROUP BY state
ORDER BY p2m_share_pct DESC;

-- 4d. State-level revenue rank (for Power BI map/drill-down default sort)
CREATE OR REPLACE VIEW vw_state_ranked AS
SELECT
    state,
    total_transactions,
    failure_rate_pct,
    revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM vw_state_summary;
