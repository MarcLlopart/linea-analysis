WITH monthly_active_addresses AS (
  SELECT 
    DATE_TRUNC('month', block_time) AS month,
    "from" AS address
  FROM linea.transactions
  WHERE block_time BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
    AND success = TRUE
  GROUP BY 1, 2
),

address_activity AS (
  SELECT 
    address,
    month,
    LAG(month) OVER (PARTITION BY address ORDER BY month) AS prev_month,
    LEAD(month) OVER (PARTITION BY address ORDER BY month) AS next_month
  FROM monthly_active_addresses
),

retention_metrics AS (
  SELECT 
    month,
    COUNT(DISTINCT address) AS total_active_addresses,
    COUNT(DISTINCT CASE 
      WHEN prev_month = month - INTERVAL '1' MONTH 
      THEN address 
    END) AS retained_addresses,
    COUNT(DISTINCT CASE 
      WHEN prev_month IS NULL OR prev_month < month - INTERVAL '1' MONTH
      THEN address 
    END) AS new_addresses,
    COUNT(DISTINCT CASE 
      WHEN next_month IS NULL OR next_month > month + INTERVAL '1' MONTH
      THEN address 
    END) AS churned_addresses
  FROM address_activity
  GROUP BY 1
)

SELECT 
  month,
  total_active_addresses,
  retained_addresses,
  new_addresses,
  churned_addresses,
  ROUND(
    CAST(retained_addresses AS DOUBLE) / 
    NULLIF(LAG(total_active_addresses) OVER (ORDER BY month), 0) * 100, 
    2
  ) AS retention_rate_pct,
  ROUND(
    CAST(new_addresses AS DOUBLE) / 
    NULLIF(total_active_addresses, 0) * 100, 
    2
  ) AS new_user_rate_pct,
  ROUND(
    CAST(churned_addresses AS DOUBLE) / 
    NULLIF(LAG(total_active_addresses) OVER (ORDER BY month), 0) * 100, 
    2
  ) AS churn_rate_pct,
  ROUND(
    (CAST(total_active_addresses AS DOUBLE) - 
     LAG(total_active_addresses) OVER (ORDER BY month)) /
    NULLIF(LAG(total_active_addresses) OVER (ORDER BY month), 0) * 100,
    2
  ) AS mom_growth_pct
FROM retention_metrics
ORDER BY month DESC;