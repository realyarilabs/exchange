use Mix.Config

# config :mnesia, dir: '.mnesia/#{Mix.env()}/#{node()}'
config :exchange, message_bus: EventBus
