WITH metamask_swaps AS (
  SELECT 
    DATE_TRUNC('month', tx.block_time) AS month,
    COUNT(DISTINCT tx.hash) AS mm_swaps,
    COUNT(DISTINCT tx."from") AS mm_users,
    SUM(CAST(tx.value AS DOUBLE) / 1e18) AS mm_native_volume_eth,
    SUM(CAST(tx.gas_price * tx.gas_used AS DOUBLE) / 1e18) AS mm_gas_cost_eth
  FROM linea.transactions tx
  WHERE tx.to = 0x9dDA6Ef3D919c9bC8885D5560999A3640431e8e6 
    AND tx.success = TRUE
    AND tx.block_time BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
  GROUP BY 1
),

dex_volume AS (
  SELECT 
    DATE_TRUNC('month', block_time) AS month,
    SUM(amount_usd) AS dex_volume_usd,
    COUNT(DISTINCT tx_hash) AS dex_trades,
    COUNT(DISTINCT taker) AS dex_traders,
    COUNT(DISTINCT project) AS active_dex_protocols
  FROM dex.trades
  WHERE blockchain = 'linea'
    AND block_time BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
  GROUP BY 1
),

eth_prices AS (
  SELECT
    DATE_TRUNC('month', minute) AS month,
    AVG(price) AS eth_usd
  FROM prices.usd
  WHERE blockchain = 'ethereum'
    AND symbol = 'WETH'
    AND minute BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
  GROUP BY 1
)

SELECT 
  COALESCE(d.month, m.month) AS month,
  COALESCE(m.mm_swaps, 0) AS metamask_swaps,
  COALESCE(m.mm_users, 0) AS swaps_active_addresses,
  ROUND(COALESCE(m.mm_native_volume_eth * p.eth_usd, 0), 2) AS swaps_usd_volume,
  ROUND(COALESCE(m.mm_gas_cost_eth * p.eth_usd, 0) / NULLIF(m.mm_swaps, 0), 4) AS avg_swap_fee_usd,
  ROUND(CAST(COALESCE(m.mm_swaps, 0) AS DOUBLE) / NULLIF(m.mm_users, 0), 2) AS swaps_per_metamask_user,
  COALESCE(d.dex_traders, 0) AS dex_addresses,
  ROUND(COALESCE(d.active_dex_protocols, 0), 0) AS dexes

FROM dex_volume d
FULL OUTER JOIN metamask_swaps m 
  ON d.month = m.month
LEFT JOIN eth_prices p 
  ON COALESCE(d.month, m.month) = p.month
ORDER BY month DESC;