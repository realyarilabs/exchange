use Mix.Config

config :exchange, environment: Mix.env()
import_config "#{Mix.env()}.exs"
