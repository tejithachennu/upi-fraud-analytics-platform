-- ============================================================
-- Query 1: Transaction Volume Trends
-- Answers: daily/monthly volume, peak hours, weekday vs weekend
-- ============================================================
USE upi_insights;

-- 1a. Daily transaction volume & value
CREATE OR REPLACE VIEW vw_daily_volume AS
SELECT
    DATE(timestamp)                    AS txn_date,
    COUNT(*)                            AS total_transactions,
    SUM(amount)                         AS total_amount,
    SUM(status = 'Success')             AS success_count,
    ROUND(SUM(status='Success') / COUNT(*) * 100, 2) AS success_rate_pct
FROM upi_transactions
GROUP BY DATE(timestamp)
ORDER BY txn_date;

-- 1b. Monthly volume & growth rate (month-over-month)
CREATE OR REPLACE VIEW vw_monthly_volume AS
SELECT
    DATE_FORMAT(timestamp, '%Y-%m')     AS txn_month,
    COUNT(*)                             AS total_transactions,
    SUM(amount)                          AS total_amount,
    ROUND(
      (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY DATE_FORMAT(timestamp,'%Y-%m')))
      / LAG(COUNT(*)) OVER (ORDER BY DATE_FORMAT(timestamp,'%Y-%m')) * 100, 2
    ) AS mom_growth_pct
FROM upi_transactions
GROUP BY DATE_FORMAT(timestamp, '%Y-%m')
ORDER BY txn_month;

-- 1c. Peak-hour analysis (hour of day, avg across the whole year)
CREATE OR REPLACE VIEW vw_hourly_pattern AS
SELECT
    HOUR(timestamp)                     AS hour_of_day,
    COUNT(*)                             AS total_transactions,
    ROUND(AVG(amount), 2)                AS avg_amount,
    ROUND(SUM(status='Failed') / COUNT(*) * 100, 2) AS failure_rate_pct
FROM upi_transactions
GROUP BY HOUR(timestamp)
ORDER BY hour_of_day;

-- 1d. Weekday vs weekend comparison
CREATE OR REPLACE VIEW vw_weekday_pattern AS
SELECT
    DAYNAME(timestamp)                  AS day_name,
    CASE WHEN DAYOFWEEK(timestamp) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*)                             AS total_transactions,
    ROUND(AVG(amount), 2)                AS avg_amount
FROM upi_transactions
GROUP BY DAYNAME(timestamp), day_type
ORDER BY FIELD(day_name,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
