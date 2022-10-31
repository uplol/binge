CREATE DATABASE IF NOT EXISTS binge;

CREATE TABLE IF NOT EXISTS binge.ingest
(
    `message` String
)
ENGINE = Null;

/* 
    https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md#trade-streams

    "e": "trade",     // Event type
    "E": 123456789,   // Event time
    "s": "BNBBTC",    // Symbol
    "t": 12345,       // Trade ID
    "p": "0.001",     // Price
    "q": "100",       // Quantity
    "b": 88,          // Buyer order ID
    "a": 50,          // Seller order ID
    "T": 123456785,   // Trade time
    "m": true,        // Is the buyer the market maker?
    "M": true         // Ignore
*/

CREATE TABLE IF NOT EXISTS binge.raw_trades
(
    `eventTime` DateTime64 CODEC(DoubleDelta),
    `symbol` LowCardinality(String),
    `tradeID` UInt64 CODEC(DoubleDelta),
    `price` Decimal128(8),
    `quantity` Decimal128(8),
    `buyOrderID` UInt64 CODEC(DoubleDelta),
    `sellOrderID` UInt64 CODEC(DoubleDelta),
    `tradeTime` DateTime64 CODEC(DoubleDelta),
    `marketMaker` Bool
)
ENGINE = MergeTree
PARTITION BY toYYYYMMDD(tradeTime)
ORDER BY (symbol, tradeTime);

CREATE MATERIALIZED VIEW IF NOT EXISTS binge.ingest_mv TO binge.raw_trades AS
SELECT
    visitParamExtractString(message, 'e') AS eventType,
    visitParamExtractUInt(message, 'E')/1e3 AS eventTime,
    visitParamExtractString(message, 's') AS symbol,
    visitParamExtractUInt(message, 't') AS tradeID,
    visitParamExtractString(message, 'p')::Decimal128(8) AS price,
    visitParamExtractString(message, 'q')::Decimal128(8) AS quantity,
    visitParamExtractUInt(message, 'b') AS buyOrderID,
    visitParamExtractUInt(message, 'a') AS sellOrderID,
    visitParamExtractUInt(message, 'T')/1e3 AS tradeTime,
    visitParamExtractBool(message, 'm') AS marketMaker
FROM binge.ingest
WHERE eventType = 'trade';

CREATE TABLE IF NOT EXISTS binge.trade_candles_agg
(
    `timestamp` DateTime32 CODEC(DoubleDelta),
    `symbol` LowCardinality(String),
    `open` AggregateFunction(argMin, Decimal128(8), UInt64),
    `high` SimpleAggregateFunction(max, Decimal128(8)),
    `low` SimpleAggregateFunction(min, Decimal128(8)),
    `close` AggregateFunction(argMax, Decimal128(8), UInt64),
    `volumeA` SimpleAggregateFunction(sum, Decimal128(8)),
    `volumeB` SimpleAggregateFunction(sum, Decimal128(16))
)
ENGINE = AggregatingMergeTree
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (symbol, timestamp);

CREATE MATERIALIZED VIEW IF NOT EXISTS binge.trade_candles_agg_mv TO binge.trade_candles_agg AS
SELECT
    toStartOfSecond(tradeTime) AS timestamp,
    symbol,
    argMinState(price, tradeID) AS open,
    maxSimpleState(price) AS high,
    minSimpleState(price) AS low,
    argMaxState(price, tradeID) AS close,
    sumSimpleState(quantity) AS volumeA, -- Volume of coin traded
    sumSimpleState(quantity * price) AS volumeB -- Equiv volume in USDT (qty * price)
FROM binge.raw_trades
GROUP BY (symbol, timestamp)
ORDER BY (symbol, timestamp);

-- Helper view for candle format (OHLCV)

CREATE VIEW IF NOT EXISTS binge.trade_candles
(
    `timestamp` DateTime32,
    `symbol` LowCardinality(String),
    `open` Decimal128(8),
    `high` Decimal128(8),
    `low` Decimal128(8),
    `close` Decimal128(8),
    `volumeA` Decimal128(8),
    `volumeB` Decimal128(16)
) AS
SELECT
    timestamp,
    symbol,
    argMinMerge(open) AS open,
    max(high) AS high,
    min(low) AS low,
    argMaxMerge(close) AS close,
    sum(volumeA) AS volumeA,
    sum(volumeB) AS volumeB
FROM binge.trade_candles_agg
GROUP BY
    timestamp,
    symbol
ORDER BY timestamp ASC;
