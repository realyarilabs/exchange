if Code.ensure_loaded?(Instream) do
  defmodule Exchange.Adapters.Flux.Connection do
    @moduledoc """
    Public API to use the adapter of `Exchange.TimeSeries`, the Flux.
    This module uses the InfluxDB to write and query the data

          config :exchange, Exchange.Adapters.Flux.Connection,
            database: System.get_env("FLUX_DB_NAME") || "dbname",
            host: System.get_env("FLUX_DB_HOST") || "localhost",
            port: System.get_env("FLUX_DB_PORT") || 8086
    """
    use Instream.Connection, otp_app: :exchange
  end
end
