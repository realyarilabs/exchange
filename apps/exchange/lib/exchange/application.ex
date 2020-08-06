defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    message_bus_children =
      case Application.get_env(:exchange, :message_bus_adapter) do
        Exchange.Adapters.EventBus ->
          [
            {Registry,
             keys: :duplicate,
             name: Exchange.Adapters.EventBus.Registry,
             partitions: System.schedulers_online()}
          ]

        _ ->
          []
      end

    time_series_children =
      case Application.get_env(:exchange, :time_series_adapter) do
        Exchange.Adapters.InMemoryTimeSeries ->
          [
            supervisor(Exchange.Adapters.InMemoryTimeSeries, [[]], id: :in_memory_time_series)
          ]

        _ ->
          []
      end

    children =
      [supervisor(Registry, [:unique, :matching_engine_registry])] ++
        message_bus_children ++
        time_series_children ++
        Exchange.Application.create_tickers()

    opts = [strategy: :one_for_one, name: Exchange.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def create_tickers do
    get_tickers_config()
    |> Enum.map(fn {ticker, currency, min_price, max_price} ->
      supervisor(
        Exchange.MatchingEngine,
        [[ticker: ticker, currency: currency, min_price: min_price, max_price: max_price]],
        id: ticker
      )
    end)
  end

  def get_tickers_config do
    Application.get_env(:exchange, __MODULE__, [])[:tickers]
  end
end
