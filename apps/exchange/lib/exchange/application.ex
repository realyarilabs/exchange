defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children =
      [supervisor(Registry, [:unique, :matching_engine_registry])] ++
        Exchange.Application.create_tickers()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
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
