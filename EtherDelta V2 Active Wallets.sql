WITH wallet_universe AS (

    -- ── SWAP THIS BLOCK FOR EACH PROTOCOL

    -- EtherDelta V2 (5000 wallets):
     SELECT address, balance_eth
     FROM dune.viktor_prinz.dataset_etherdelta_v2
),

all_chain_txns AS (

    -- ── 1. Ethereum Mainnet 
    SELECT
        t."from"                                    AS wallet,
        'ethereum'                                  AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM ethereum.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

    UNION ALL

    -- ── 2. Arbitrum One 
    SELECT
        t."from"                                    AS wallet,
        'arbitrum'                                  AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM arbitrum.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

    UNION ALL

    -- ── 3. Optimism 
    SELECT
        t."from"                                    AS wallet,
        'optimism'                                  AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM optimism.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

    UNION ALL

    -- ── 4. Base 
    SELECT
        t."from"                                    AS wallet,
        'base'                                      AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM base.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

    UNION ALL

    -- ── 5. Polygon 
    SELECT
        t."from"                                    AS wallet,
        'polygon'                                   AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM polygon.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

    UNION ALL

    -- ── 6. BNB Chain 
    SELECT
        t."from"                                    AS wallet,
        'bnb'                                       AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM bnb.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

    UNION ALL

    -- ── 7. Avalanche C-Chain
    SELECT
        t."from"                                    AS wallet,
        'avalanche_c'                               AS chain,
        t.block_time,
        CASE WHEN LENGTH(t.data) > 4 THEN 'contract' ELSE 'transfer' END AS tx_type
    FROM avalanche_c.transactions t
    INNER JOIN wallet_universe w ON t."from" = w.address
    WHERE t.block_time >= TIMESTAMP '2022-01-01'
      AND t.success = true

),

-- ── Aggregate per wallet across all chains 

raw_activity AS (
    SELECT
        wallet,
        COUNT(*)                                                AS total_txns,
        COUNT(*) FILTER (WHERE tx_type = 'contract')           AS contract_txns,
        COUNT(*) FILTER (WHERE tx_type = 'transfer')           AS transfer_txns,
        COUNT(DISTINCT chain)                                   AS chain_count,
        MAX(block_time)                                         AS last_tx_date,
        MIN(block_time)                                         AS first_tx_since_2022,
        COUNT(DISTINCT DATE_TRUNC('month', block_time))         AS active_months,

        -- Per-chain transaction counts (useful for outreach context)
        COUNT(*) FILTER (WHERE chain = 'ethereum')             AS eth_txns,
        COUNT(*) FILTER (WHERE chain = 'arbitrum')             AS arb_txns,
        COUNT(*) FILTER (WHERE chain = 'optimism')             AS op_txns,
        COUNT(*) FILTER (WHERE chain = 'base')                 AS base_txns,
        COUNT(*) FILTER (WHERE chain = 'polygon')              AS polygon_txns,
        COUNT(*) FILTER (WHERE chain = 'bnb')                  AS bnb_txns,
        COUNT(*) FILTER (WHERE chain = 'avalanche_c')          AS avax_txns,

        -- Most active chain (highest tx count) — key outreach signal
        -- Tells you WHERE to find them (e.g. Base-native users vs ETH maxis)
        CASE
            WHEN COUNT(*) FILTER (WHERE chain = 'ethereum')   >= COUNT(*) FILTER (WHERE chain = 'arbitrum')
             AND COUNT(*) FILTER (WHERE chain = 'ethereum')   >= COUNT(*) FILTER (WHERE chain = 'optimism')
             AND COUNT(*) FILTER (WHERE chain = 'ethereum')   >= COUNT(*) FILTER (WHERE chain = 'base')
             AND COUNT(*) FILTER (WHERE chain = 'ethereum')   >= COUNT(*) FILTER (WHERE chain = 'polygon')
             AND COUNT(*) FILTER (WHERE chain = 'ethereum')   >= COUNT(*) FILTER (WHERE chain = 'bnb')
             AND COUNT(*) FILTER (WHERE chain = 'ethereum')   >= COUNT(*) FILTER (WHERE chain = 'avalanche_c')
                THEN 'ethereum'
            WHEN COUNT(*) FILTER (WHERE chain = 'arbitrum')   >= COUNT(*) FILTER (WHERE chain = 'optimism')
             AND COUNT(*) FILTER (WHERE chain = 'arbitrum')   >= COUNT(*) FILTER (WHERE chain = 'base')
             AND COUNT(*) FILTER (WHERE chain = 'arbitrum')   >= COUNT(*) FILTER (WHERE chain = 'polygon')
             AND COUNT(*) FILTER (WHERE chain = 'arbitrum')   >= COUNT(*) FILTER (WHERE chain = 'bnb')
             AND COUNT(*) FILTER (WHERE chain = 'arbitrum')   >= COUNT(*) FILTER (WHERE chain = 'avalanche_c')
                THEN 'arbitrum'
            WHEN COUNT(*) FILTER (WHERE chain = 'base')       >= COUNT(*) FILTER (WHERE chain = 'optimism')
             AND COUNT(*) FILTER (WHERE chain = 'base')       >= COUNT(*) FILTER (WHERE chain = 'polygon')
             AND COUNT(*) FILTER (WHERE chain = 'base')       >= COUNT(*) FILTER (WHERE chain = 'bnb')
             AND COUNT(*) FILTER (WHERE chain = 'base')       >= COUNT(*) FILTER (WHERE chain = 'avalanche_c')
                THEN 'base'
            WHEN COUNT(*) FILTER (WHERE chain = 'optimism')   >= COUNT(*) FILTER (WHERE chain = 'polygon')
             AND COUNT(*) FILTER (WHERE chain = 'optimism')   >= COUNT(*) FILTER (WHERE chain = 'bnb')
             AND COUNT(*) FILTER (WHERE chain = 'optimism')   >= COUNT(*) FILTER (WHERE chain = 'avalanche_c')
                THEN 'optimism'
            WHEN COUNT(*) FILTER (WHERE chain = 'polygon')    >= COUNT(*) FILTER (WHERE chain = 'bnb')
             AND COUNT(*) FILTER (WHERE chain = 'polygon')    >= COUNT(*) FILTER (WHERE chain = 'avalanche_c')
                THEN 'polygon'
            WHEN COUNT(*) FILTER (WHERE chain = 'bnb')        >= COUNT(*) FILTER (WHERE chain = 'avalanche_c')
                THEN 'bnb'
            ELSE 'avalanche_c'
        END                                                    AS most_active_chain

    FROM all_chain_txns
    GROUP BY wallet
),

-- ── STEP 4: Apply ≥5 txn filter 

active_wallets AS (
    SELECT *
    FROM raw_activity
    WHERE total_txns >= 5
),

-- ── STEP 5: Enrich with ETH balance data and rank 

final AS (
    SELECT
        RANK() OVER (ORDER BY w.balance_eth DESC)               AS eth_rank,
        '0x' || LOWER(TO_HEX(w.address))                        AS wallet_address,
        w.balance_eth                                            AS forgotten_eth,
        ROUND(CAST(w.balance_eth AS DOUBLE) * 3200, 2)         AS usd_value_approx,
        a.total_txns,
        a.chain_count,
        a.most_active_chain,
        CAST(a.last_tx_date AS DATE)                            AS last_tx_date
 
    FROM wallet_universe w
    INNER JOIN active_wallets a
        ON w.address = a.wallet
)

SELECT *
FROM final
ORDER BY
    forgotten_eth DESC,
    last_tx_date  DESC
LIMIT 500