defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  @spec start(any, any) :: {:error, any} | {:ok, pid}
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

        Exchange.Adapters.TestEventBus ->
          [supervisor(Exchange.Adapters.TestEventBus, [Qex.new()])]

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

  @doc """
  Creates the necessary supervisors to run the application's markets which are obtained through the `config.exs`
  """
  @spec create_tickers :: list
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

  @doc """
  Fetches the application configuration corresponding to the `tickers` key
  """
  @spec get_tickers_config :: list
  def get_tickers_config do
    ticker_list = Application.get_env(:exchange, __MODULE__, [])

    if ticker_list != [] do
      ticker_list[:tickers]
    end
  end
end
