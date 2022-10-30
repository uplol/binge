-- Top ten coin pairs by trade count (all time)

SELECT
    symbol,
    count() AS count
FROM raw_trades
GROUP BY symbol
ORDER BY count DESC
LIMIT 10;

-- Top ten coin pairs by amount of USDT spent (all time)

SELECT
    symbol,
    round(sum(quantity * price), 0) AS USDT
FROM raw_trades
GROUP BY symbol
ORDER BY USDT DESC
LIMIT 10;

-- Count of trades per hour by for a given coin pair

SELECT
    toHour(tradeTime) AS time,
    count() AS c,
    bar(c, 0, 15000000)
FROM raw_trades
WHERE (symbol = 'BTCUSDT') AND (tradeTime < toStartOfDay(now()))
GROUP BY time
ORDER BY time ASC;

SELECT
    toHour(t) AS hour,
    round(avg(c), 0) AS average,
    bar(average, 0, 1500000) AS bar
FROM
(
    SELECT
        toStartOfHour(tradeTime) AS t,
        count() AS c
    FROM raw_trades
    GROUP BY t
)
GROUP BY hour
ORDER BY hour ASC;
