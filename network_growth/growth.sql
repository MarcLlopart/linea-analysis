
WITH linea_data AS (
    SELECT 
        'linea' as blockchain,
        DATE_TRUNC('month', t.block_time) as date, 
        COUNT(DISTINCT t.hash) as transactions, 
        COUNT(DISTINCT t."from") as monthly_active_addresses,
        AVG(g.tx_fee_usd) as avg_tx_fee
    FROM linea.transactions as t
    JOIN gas.fees as g ON g.blockchain = 'linea'
                  AND g.block_time = t.block_time
    WHERE DATE(t.block_time) BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
    GROUP BY 1, 2
),
zksync_data AS (
    SELECT 
        'zksync' as blockchain,
        DATE_TRUNC('month', t.block_time) as date, 
        COUNT(DISTINCT t.hash) as transactions, 
        COUNT(DISTINCT t."from") as monthly_active_addresses,
        AVG(g.tx_fee_usd) as avg_tx_fee
    FROM zksync.transactions as t
    JOIN gas.fees as g ON g.blockchain = 'zksync'
                  AND g.block_time = t.block_time
    WHERE DATE(t.block_time) BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
    GROUP BY 1, 2
),
zkevm_data AS (
    SELECT 
        'zkevm' as blockchain,
        DATE_TRUNC('month', t.block_time) as date, 
        COUNT(DISTINCT t.hash) as transactions, 
        COUNT(DISTINCT t."from") as monthly_active_addresses,
        AVG(g.tx_fee_usd) as avg_tx_fee
    FROM zkevm.transactions as t
    JOIN gas.fees as g ON g.blockchain = 'zkevm'
                  AND g.block_time = t.block_time
    WHERE DATE(t.block_time) BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
    GROUP BY 1, 2
),
scroll_data AS (
    SELECT 
        'scroll' as blockchain,
        DATE_TRUNC('month', t.block_time) as date, 
        COUNT(DISTINCT t.hash) as transactions, 
        COUNT(DISTINCT t."from") as monthly_active_addresses,
        AVG(g.tx_fee_usd) as avg_tx_fee
    FROM scroll.transactions as t
    JOIN gas.fees as g ON g.blockchain = 'scroll'
                  AND g.block_time = t.block_time
    WHERE DATE(t.block_time) BETWEEN DATE('2024-01-01') AND DATE('2025-11-30')
    GROUP BY 1, 2
)
SELECT * FROM linea_data
UNION ALL
SELECT * FROM zksync_data
UNION ALL
SELECT * FROM zkevm_data
UNION ALL
SELECT * FROM scroll_data
ORDER BY blockchain, date;