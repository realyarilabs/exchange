# Flux

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flux` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flux, "~> 0.1.0"}
  ]
end
```

## Flux depends on InfluxDB

# Quick Start

> influx -precision rfc3339
opens the InfluxDB shell if the server is properly installed and running as a
service.

InfluxDB API runs on port 8086 by default.
> influx --help for help
the precision argument specifies the format/precision of any returned
timestamps. rfc3339 tells influx db to return timestamps in that format:
`YYYY-MM-DDTHH:MM:SS.nnnnnnnnnZ`

Quickstart

InfluxDB shell version: v1.7.9
> CREATE DATABASE mydb
> SHOW databases
name: databases
mydb

> USE mydb
> INSERT cpu,host=serverA,region=us_west value=0.64

```elixir
# Create a Database

"CREATE DATABASE alchemist" |> Flux.Connection.execute(method: :post)
```


Examples of valid points with lines that follow InfluxDB line protocol syntax

```
cpu,host=serverA,region=us_west value=0.64
payment,device=mobile,product=Notepad,method=credit billed=33,licenses=3i 1434067467100293230
stock,symbol=AAPL bid=127.46,ask=127.48
temperature,machine=unit42,type=assembly external=25,internal=37 1434067467000000000
```

## some examples applied to exchange data
```
> INSERT trades,exchange=binance,pair=btcusdt trade_id=100,price=8200.0,side="sell",amount=0.21 1527867107000
```
-This adds a sample trade to the trades measurement 
-exchange and pair are tags 
-trade_id, price, side and amount are fields because we don’t need those fields to be indexed. 
-At the end we set the timestamp of the data. 
If that is not provided InfluxDB automatically set the present time as the timestamp which is epoch in nano seconds.

We can check it out with:

```
select * from trades
```

If we want to get all the tags we have defined we can issue:

```
> show tag keys

name: cpu
tagKey
------
host
region

name: temperature
tagKey
------
machine
type

name: trades
tagKey
------
exchange
pair
```
And we get all the measurements and and associated tag keys 

Maybe the most important concept in InfluxDB is series, which is a collection of data with common retention policy, measurement and tag set. 
A point is is the field set in the same series with a specific timestamp e.g.time=2015-08-18T00:00:00Z, minors=1, adults=2, location=1, driver=doe. 

```
> show series
key
---
cpu,host=serverA,region=us_west
temperature,machine=unit42,type=assembly
trades,exchange=binance,pair=btcusdt
```

If we insert a new point with different values for tags it becomes another
series

```
> INSERT trades,exchange=bitfinex,pair=btcusd trade_id=23100,price=8100.0,side="buy",amount=1.43 1527121437000000000
> show series
key
---
trades,exchange=binance,pair=btcusdt
trades,exchange=bitfinex,pair=btcusd
```

If for example we want  to agregate data for candle sticks charts we could use a
query like this:


```sql
SELECT first(price) AS open, last(price) AS close, max(price) AS high, min(price) AS low, sum(amount) AS volume 
FROM trades 
WHERE exchange='binance' AND pair='btcusdt' AND time > 1525777200000 and time < 1525831200000 
GROUP BY time(1h), pair, exchange
```

For a large number of trades, it is not very efficient to construct the candles on runtime. 
It is possible to use the *INTO* clause to insert them in a separate measurement. 
Afterwards you can build higher interval candlesticks from smaller candles. 
For example if you have 1m candles and you want to build the 5m candles you will have:

more info: https://docs.influxdata.com/influxdb/v1.5/query_language/data_exploration/#the-into-clause

```
SELECT max(high) AS high, min(low) AS low, first(open) AS open, last(close) AS close, sum(volume) AS volume 
FROM candles_1m GROUP BY time(5m), pair, exchange
```

### Continuous Queries and Real-time data Aggregation

For any financial market it is necessary to get real-time data as they are produced. 
The same goes for any cryptocurrency exchange. You can either get the latest data through API or websockets. 
When receiving trade data, you would want to aggregate them on different time intervals to update the latest candle. 
InfluxDB has a feature named ( continuous queries ) which allows you to run queries periodically on real-time data and store them in a specific measurement. For example, in our case as new trades come in we want to make sure that the candlestick for the latest interval is updated accordingly. Moreover, you can also aggregate a few recent intervals in case you had some connection loss and you’ve updated the trades with the missing trades. 

https://docs.influxdata.com/influxdb/v1.5/query_language/continuous_queries/

Therefore you can create a continuous query such as:

```
CREATE CONTINUOUS QUERY trade_to_candles_60 ON mydb 
RESAMPLE EVERY 10s FOR 10m 
BEGIN SELECT first(price) AS open, last(price) AS close, max(price) AS high, min(price) AS low, sum(amount) AS volume INTO 
candles_1m FROM trades WHERE 
GROUP BY time(1m), pair, exchange END
```
This is an advanced example of continuous queries. They query between BEGINand END creates candlesticks on 1m interval (group by time(1m) ) and inserts it into candle_1m measurement. RESAMPLE EVERY 10s executes this query once every 10 seconds. FOR 10m runs this query in the range of now and 10 minutes ago meaning in this case the last 10 candles will be reconstructed and overwritten. So with real-time data, the aggregation of candlesticks happens every 10 seconds.
Once you have 1m candlesticks you can easily aggregate them with more continuous queries to construct bigger time intervals.
Continuous queries are very powerful to deal with real-time data and saves a lot of time and resources to run your own periodic jobs.

Summarized from:
https://medium.com/coinograph/storing-and-processing-billions-of-cryptocurrency-market-data-using-influxdb-f9f670b50bbd

### Possible model to store prices 
Have a single measurement *stock_price* with two *tags* ticker and exchange, and three *fields* bid, ask, and value.

`asset_price,ticker=<symbol>,exchange=<exchange> bid=1,ask=10,value=17 <timestamp_1>`
`asset_price,ticker=AUXGBP, exchange=AUXLND bid=4200,ask=4150,value=17 <timestamp_1>`

like this we can now do queries like:

```sql
SELECT max(value) FROM asset_price WHERE time > now() - 30d AND exchange = 'AUXLND' GROUP BY time(1d), ticker
```


# Marketing for Influx DB

InfluxDB is an open source database specialized in handling time series data with high availability and high performance requirements. It’s the world’s top ranked time series database, according to the DB-Engines Ranking of Time Series DBMS.

Benefits of InfluxDB include:

Easy installation with zero dependencies, yet highly extensible
Store up to one million values per second
Time-centric functions with a simple SQL-like query language
Supports data tagging for flexible queries
Highly efficient compression to reduce storage footprint
Supports a range of high-availability and clustering schemes
Market data is the foundation upon which quantitative trading strategies are built. It’s often necessary to store and process vast amounts of historical data to back test and run strategies. InfluxDB simplifies this process and enables AlgoTrader to deliver the following new features:

Record live tick data (one million ticks per second)
Storage of downloaded historical data
Automatically store end-of-day market data
Speed up back tests by up to 200%
Store fundamental data
Real-time aggregation of tick data into bar data
Replay historical data for back testing
During our benchmark testing, InfluxDB easily handled the storage of 100 billion ticks on a simple laptop.

InfluxDB is available for Windows, Mac and Linux. On production servers, InfluxDB can also be installed via Docker.

The AlgoTrader InfluxDB integration will be made available to all AlgoTrader users when version 3.1 is released later this spring.
