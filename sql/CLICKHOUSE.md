# Clickhouse

## Finding a suitable schema

The goal of this article is to find an optimal balance between storage usage, insert throughput, and query speed for some examples queries of the `binge.raw_trades` table.

> **Note**
>
> For this writeup, we are utilizing 200M rows of actual trade data to easily show the impacts of different schemas. However, you can still optimize the schema using less rows. **Also of note, all queries are performed after [OPTIMIZE FINAL](https://clickhouse.com/docs/en/sql-reference/statements/optimize/) has been run against the table.**

### Base Table

We start off with this basic table so we have a consistent base to compare to. Nothing special is going on with this, we merely take in the data in the data type presented to us from the Binance API and partition and order by `eventTime`.

```sql
CREATE TABLE IF NOT EXISTS binge.benchmark_base
(
    `eventTime` DateTime64,
    `symbol` String,
    `tradeID` UInt64,
    `price` Decimal128(8),
    `quantity` Decimal128(8),
    `buyOrderID` UInt64,
    `sellOrderID` UInt64,
    `tradeTime` DateTime64,
    `marketMaker` Bool
)
ENGINE = MergeTree
PARTITION BY toYYYYMMDD(eventTime)
ORDER BY (eventTime);
```

### Working through the data

Let's first take a look at the size of the base table using [this](https://kb.altinity.com/altinity-kb-useful-queries/altinity-kb-database-size-table-column-size/#table-size) query from the Altinity Knowledge Base.

```sql
SELECT
    database,
    table,
    formatReadableSize(sum(data_compressed_bytes) AS size) AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes) AS usize) AS uncompressed,
    round(usize / size, 2) AS compr_rate,
    sum(rows) AS rows,
    count() AS part_count
FROM system.parts
WHERE (active = 1) AND (database = 'binge') AND (table = 'benchmark_base')
GROUP BY
    database,
    table
ORDER BY size DESC;
```

```text
┌─database─┬─table──────────┬─compressed─┬─uncompressed─┬─compr_rate─┬─rows─┬─part_count─┐
│ binge    │ benchmark_base │ 319.00 B   │ 83.00 B      │       0.26 │    1 │          1 │
└──────────┴────────────────┴────────────┴──────────────┴────────────┴──────┴────────────┘

1 row in set. Elapsed: 0.006 sec.
```

For a deeper look into each column, we can use [this](https://kb.altinity.com/altinity-kb-useful-queries/altinity-kb-database-size-table-column-size/#column-size) query.

```sql
SELECT
    database,
    table,
    column,
    formatReadableSize(sum(column_data_compressed_bytes) AS size) AS compressed,
    formatReadableSize(sum(column_data_uncompressed_bytes) AS usize) AS uncompressed,
    round(usize / size, 2) AS compr_ratio,
    sum(rows) AS rows_cnt,
    round(usize / rows_cnt, 2) AS avg_row_size
FROM system.parts_columns
WHERE (active = 1) AND (database = 'binge') AND (table = 'benchmark_base')
GROUP BY
    database,
    table,
    column
ORDER BY
    database,
    table,
    column;
```

```text
┌─database─┬─table──────────┬─column──────┬─compressed─┬─uncompressed─┬─compr_ratio─┬─rows_cnt─┬─avg_row_size─┐
│ binge    │ benchmark_base │ tradeID     │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ price       │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ eventTime   │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ sellOrderID │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ quantity    │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ marketMaker │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ buyOrderID  │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ symbol      │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
│ binge    │ benchmark_base │ tradeTime   │ 0.00 B     │ 0.00 B       │         nan │        1 │            0 │
└──────────┴────────────────┴─────────────┴────────────┴──────────────┴─────────────┴──────────┴──────────────┘

9 rows in set. Elapsed: 0.007 sec.
```
