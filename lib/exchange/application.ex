defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    time_series_adapter =
      Application.get_env(:exchange, :time_series_adapter, Exchange.Adapters.InMemoryTimeSeries)

    message_bus_module =
      Application.get_env(:exchange, :message_bus_adapter, Exchange.Adapters.EventBus)

    with {:ok, time_series_children} <- time_series_adapter.init(),
         {:ok, message_bus_children} <- message_bus_module.init() do
      children =
        [supervisor(Registry, [:unique, :matching_engine_registry])] ++
          message_bus_children ++
          time_series_children ++
          Exchange.Application.create_tickers()

      opts = [strategy: :one_for_one, name: Exchange.Supervisor]
      Supervisor.start_link(children, opts)
    else
      err -> err
    end
  end

  @doc """
  Creates the necessary supervisors to run the application's markets which are obtained through the `config.exs`
  """
  @spec create_tickers :: list
  def create_tickers do
    tickers = Application.get_env(:exchange, :tickers, [])

    if Enum.all?(tickers, fn ticker ->
         is_tuple(ticker) and tuple_size(ticker) == 4
       end) do
      tickers
      |> Enum.map(fn ticker_config when is_tuple(ticker_config) ->
        {ticker, currency, min_price, max_price} = ticker_config

        supervisor(
          Exchange.MatchingEngine,
          [[ticker: ticker, currency: currency, min_price: min_price, max_price: max_price]],
          id: ticker
        )
      end)
    else
      raise RuntimeError, message: "Invalid ticker configuration"
    end
  end
end
