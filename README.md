# BINGE (Binance INGEstor)

BINGE is a simple pipeline to ingest raw trades from [Binance](https://www.binance.com/), into [Clickhouse](https://clickhouse.com/), using [Vector](https://vector.dev/) to handle the insertion, and [Grafana](https://grafana.com/oss/grafana/) to power some simple visualizations.

Binge is a simplified version of internal tooling, which has been processing Binance trades, on and off, for several years. Binge is setup to subscribe to and ingest coins that are actively traded against USDT (BTCUSDT, ETHUSDT, etc..), however one can easily extend the coins ingested with minor tweaks to [binge.py](binge/binge.py). 

## Setup

### Docker

Bring up binge using docker compose:

```bash
docker compose up
```

### Manual Setup

#### Pre-requisites

* Clickhouse
* Grafana
    * [Clickhouse-Datasource](https://github.com/grafana/clickhouse-datasource)
* Python3
    * Poetry
* Vector

#### Steps

1. Import the the required tables and views into clickhouse:

    ```bash
    clickhouse-client --queries-file ./sql/clickhouse.sql
    ```

1. Setup python and run binge:
    ```bash
    cd binge
    poetry install
    poetry shell
    python binge.py | vector --config-toml ../vector/vector.toml
    ```

1. Follow the official [Import a Dashboard](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#import-a-dashboard) steps to import the example dashboards located in the [grafana](grafana/) directory to your Grafana instance.
