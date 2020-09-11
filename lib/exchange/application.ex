defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    with {:ok, time_series_children} <- setup_time_series(),
         {:ok, message_bus_children} <- setup_message_bus() do
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
  Setup for the time series adapters shipped with the Exchange application.
  This function return a list of children necessary for the proper execution of the adapters for InfluxDB and in memory DB.
  """
  @spec setup_time_series() :: {:ok, list()} | {:error, String.t()}
  def setup_time_series do
    time_series_module = Application.get_env(:exchange, :time_series_adapter)

    if time_series_module == nil do
      {:error, "Invalid time series adapter"}
    else
      case time_series_module do
        Exchange.Adapters.InMemoryTimeSeries ->
          {:ok,
           [
             supervisor(Exchange.Adapters.InMemoryTimeSeries, [[]], id: :in_memory_time_series)
           ]}

        Exchange.Adapters.Flux ->
          time_series_module.validate_config(
            Application.get_env(:exchange, Exchange.Adapters.Flux.Connection)
          )

          {:ok,
           [
             Exchange.Adapters.Flux.Connection,
             Exchange.Adapters.Flux.EventListener
           ]}

        other ->
          Application.ensure_all_started(other)
          {:ok, []}
      end
    end
  end

  @doc """
  Setup for the message bus adapters shipped with the Exchange application.
  This function return a list of children necessary for the proper execution of the adapters that use the `Registry` and RabbitMQ
  """
  @spec setup_message_bus() :: {:ok, list()} | {:error, String.t()}
  def setup_message_bus do
    message_bus_module = Application.get_env(:exchange, :message_bus_adapter)

    if message_bus_module == nil do
      {:error, "Invalid message bus adapter"}
    else
      case message_bus_module do
        Exchange.Adapters.RabbitBus ->
          message_bus_module.setup_resources()

          {:ok,
           [
             Exchange.Adapters.RabbitBus.Consumer,
             Exchange.Adapters.RabbitBus.Producer
           ]}

        Exchange.Adapters.EventBus ->
          {:ok,
           [
             {Registry,
              keys: :duplicate,
              name: Exchange.Adapters.EventBus.Registry,
              partitions: System.schedulers_online()}
           ]}

        Exchange.Adapters.TestEventBus ->
          {:ok, [supervisor(Exchange.Adapters.TestEventBus, [Qex.new()])]}

        _ ->
          {:ok, []}
      end
    end
  end

  @doc """
  Creates the necessary supervisors to run the application's markets which are obtained through the `config.exs`
  """
  @spec create_tickers :: list
  def create_tickers do
    tickers = get_tickers_config()

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

  @doc """
  Fetches the application configuration corresponding to the `tickers` key
  """
  @spec get_tickers_config :: list
  def get_tickers_config do
    Application.get_env(:exchange, :tickers, [])
  end
end
