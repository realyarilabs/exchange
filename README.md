# AlchemistExchange

# Environment Variables

There are some required environment variables to run the umbrella application.
There is an example with default values for these in the file `.sample-env`.
In order to manage your environment variables I recommend setting up direnv (https://direnv.net/) and creating a `.envrc` file with your custom variables.

# Install InfluxDB

- Install InfluxDB (optionally install entire TICK stack).
- Create database named "alchemist" @ localhost:8086.

## MacOS - Homebrew

- Install and start required services.
  
```shell
brew install influxdb
brew install telegraf
brew install chronograf
brew services start influxdb 
brew services start telegraf
brew services start chronograf
brew services start kapacitor
```

- Navigate to http://localhost:8888/ to open Chronograf
- Follow setup instructions.
- Once complete, navigate to "InfluxDB Admin" section.
- Create a database named "alchemist".

## Ubuntu

- Add the InfluxData repository.
  
```shell
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
```

or

```shell
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
```

- Install and start InfluxDB.

```shell
sudo apt-get update && sudo apt-get install influxdb
sudo service influxdb start
influx
CREATE DATABASE alchemist
```

- Optionally install the rest of the TICK stack: https://docs.influxdata.com/platform/installation/oss-install/


## Docker Sandbox

https://github.com/influxdata/sandbox

## Alternatives

https://portal.influxdata.com/downloads/

# Starting the Umbrella

Once you have set up your environment variables and installed influxdb, you should be able to run the app interactively with  `iex -S mix` in your terminal.
