WITH linea_addresses AS (
  SELECT DISTINCT "from" AS address
  FROM linea.transactions
  WHERE block_time BETWEEN DATE('2025-11-01') AND DATE('2025-11-30')
    AND success = TRUE
),

cross_chain_activity AS (
  SELECT 
    t.blockchain,
    COUNT(DISTINCT t."from") AS unique_linea_addresses,
    COUNT(DISTINCT t.hash) AS total_transactions,
    MIN(t.block_time) AS first_tx_date,
    MAX(t.block_time) AS last_tx_date
  FROM evms.transactions t
  INNER JOIN linea_addresses la ON t."from" = la.address
  WHERE t.block_time BETWEEN DATE('2025-11-01') AND DATE('2025-11-30')
    AND t.success = TRUE
    AND t.blockchain != 'linea' 
  GROUP BY t.blockchain
)

SELECT 
  blockchain,
  unique_linea_addresses,
  ROUND(
    unique_linea_addresses * 100.0 / 
    (SELECT COUNT(DISTINCT address) FROM linea_addresses),
    2
  ) AS pct_of_linea_users,
  total_transactions,
  ROUND(
    CAST(total_transactions AS DOUBLE) / unique_linea_addresses,
    2
  ) AS avg_txs_per_address,
  first_tx_date,
  last_tx_date
FROM cross_chain_activity
ORDER BY unique_linea_addresses DESC;