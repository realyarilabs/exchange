use Mix.Config

config :flux, Flux.Connection,
  database: System.get_env("FLUX_DB_NAME") || "alchemist",
  host: System.get_env("FLUX_DB_HOST") || "localhost",
  http_opts: [insecure: true],
  pool: [max_overflow: 10, size: 50],
  port: System.get_env("FLUX_DB_PORT") || 8086,
  scheme: "http",
  writer: Instream.Writer.Line


config :flux, Flux.EventListener,
  message_bus_adapter: EventBus

config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:application, :pid, :query_time, :response_status]
