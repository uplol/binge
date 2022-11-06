# BINGE (Binance INGEstor)

BINGE is a simple pipeline to ingest raw trades from [Binance](https://www.binance.com/), into [Clickhouse](https://clickhouse.com/), using [Vector](https://vector.dev/) to handle the insertion, and [Grafana](https://grafana.com/oss/grafana/) to power some simple visualizations.

Binge is a simplified version of internal tooling, which has been processing Binance trades, on and off, for several years. Binge is setup to subscribe to and ingest coins that are actively traded against USDT (BTCUSDT, ETHUSDT, etc..), however one can easily extend the coins ingested with minor tweaks to [binge.py](binge/binge.py).

![image](https://user-images.githubusercontent.com/21028558/198904944-5390e2b9-359d-441e-b865-f39129e2dbba.png)

## Setup

### Docker

1. Bring up binge using docker compose:

   ```bash
   docker compose up
   ```

1. Connect to Grafana: <http://localhost:3001>

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

1. Configure [vector](vector/vector.toml.example) with the appropriate endpoint and credentials information to sink into clickhouse.

1. Setup python and run binge:

    ```bash
    cd binge
    poetry install
    poetry shell
    python binge.py | vector --config-toml ../vector/vector.toml
    ```

1. Follow the official [Import a Dashboard](https://grafana.com/docs/grafana/latest/dashboards/manage-dashboards/#import-a-dashboard) steps to import the example dashboards located in the [grafana](grafana/) directory to your Grafana instance.

   > **Note**
   >
   > To enable sub 5 second refresh rates, you will need to modify your grafana.ini [min_refresh_interval](https://grafana.com/docs/grafana/v9.0/setup-grafana/configure-grafana/#min_refresh_interval) setting to allow faster refresh rates.
