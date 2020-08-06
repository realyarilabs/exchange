defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    message_bus_adapter = Application.get_env(:exchange, :message_bus_adapter, nil)

    message_bus_child =
      if message_bus_adapter do
        [supervisor(Exchange.Adapters.TestEventBus, [Qex.new()])]
      else
        []
      end

    children =
      [supervisor(Registry, [:unique, :matching_engine_registry])] ++
        message_bus_child ++
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
    ticker_list = Application.get_env(:exchange, __MODULE__, [])

    if ticker_list != [] do
      ticker_list[:tickers]
    end
  end
end
