defmodule Exchange.Adapters.InMemoryTimeSeries do
  @moduledoc """
  Public API to use the adapter of `Exchange.TimeSeries`, the InMemoryTimeSeries.
  This adapter is an approach of an in memory time series database and it keeps state about orders, prices and trades.
  """
  use GenServer
  use Exchange.TimeSeries, required_config: [], required_deps: []
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{orders: %{}, prices: %{}, trades: %{}},
      name: :in_memory_time_series
    )
  end

  def init(state) do
    message_bus().add_listener(:trade_executed)
    message_bus().add_listener(:order_queued)
    message_bus().add_listener(:order_cancelled)
    message_bus().add_listener(:order_expired)
    message_bus().add_listener(:price_broadcast)
    {:ok, state}
  end

  def handle_info(
        {:cast_event, :trade_executed, %Exchange.Adapters.MessageBus.TradeExecuted{} = payload},
        state
      ) do
    Logger.info("[InMemoryTimeSeries] Processing trade: #{inspect(payload.trade)}")

    state =
      payload.trade
      |> save_trade(state)

    {:noreply, state}
  end

  def handle_info(
        {:cast_event, :order_queued, %Exchange.Adapters.MessageBus.OrderQueued{} = payload},
        state
      ) do
    Logger.info("[InMemoryTimeSeries] Processing Order: #{inspect(payload.order)}")
    state = save_order(payload.order, state)
    {:noreply, state}
  end

  def handle_info(
        {:cast_event, :order_cancelled, %Exchange.Adapters.MessageBus.OrderCancelled{} = payload},
        state
      ) do
    Logger.info("[InMemoryTimeSeries] Processing Order: #{inspect(payload.order)}")
    order = payload.order

    state =
      %{order | size: 0}
      |> save_order(state)

    {:noreply, state}
  end

  def handle_info(
        {:cast_event, :order_expired, %Exchange.Adapters.MessageBus.OrderExpired{} = payload},
        state
      ) do
    Logger.info("[InMemoryTimeSeries] Processing Order: #{inspect(payload.order)}")
    order = payload.order

    state =
      %{order | size: 0}
      |> save_order(state)

    {:noreply, state}
  end

  def handle_info(
        {:cast_event, :price_broadcast, %Exchange.Adapters.MessageBus.PriceBroadcast{} = price},
        state
      ) do
    Logger.info("[InMemoryTimeSeries] Processing Price: #{inspect(price)}")

    state =
      %{ticker: price.ticker, ask_min: price.ask_min, bid_max: price.bid_max}
      |> save_price(state)

    {:noreply, state}
  end

  def handle_call(:flush, _from, _state) do
    {:reply, :ok, %{orders: %{}, prices: %{}, trades: %{}}}
  end

  def handle_call(:state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:trades_by_id, ticker, trader_id}, _from, state) do
    {:ok, trades} = Map.fetch(state, :trades)

    trades_by_id =
      trades
      |> Enum.flat_map(fn {_ts, queue} -> queue end)
      |> Enum.filter(fn trade ->
        (trade.buyer_id == trader_id or trade.seller_id == trader_id) and
          trade.ticker == ticker
      end)

    {:reply, {:ok, trades_by_id}, state}
  end

  def handle_call({:live_orders, ticker}, _from, state) do
    {:ok, orders} = Map.fetch(state, :orders)

    in_memory_orders =
      orders
      |> Enum.flat_map(fn {_ts, queue} -> queue end)
      |> Enum.filter(fn order ->
        order.ticker == ticker and order.size > 0
      end)

    {:reply, {:ok, in_memory_orders}, state}
  end

  def handle_call({:completed_trades, ticker}, _from, state) do
    {:ok, trades} = Map.fetch(state, :trades)

    in_memory_trades =
      trades
      |> Enum.flat_map(fn {_ts, queue} -> queue end)
      |> Enum.filter(fn trade ->
        trade.ticker == ticker
      end)

    {:reply, {:ok, in_memory_trades}, state}
  end

  @spec save(item :: any, timestamp :: number, state :: map) :: map
  def save(item, timestamp, state_map) do
    current_queue =
      case Map.fetch(state_map, timestamp) do
        {:ok, value} -> value
        :error -> nil
      end

    updated_queue =
      if current_queue do
        Qex.push(current_queue, item)
      else
        Qex.new([item])
      end

    Map.put(state_map, timestamp, updated_queue)
  end

  @spec save_price(price :: map, state :: map) :: map
  def save_price(price, state) do
    current_time = :os.system_time(:nanosecond)
    {:ok, prices} = Map.fetch(state, :prices)
    update_prices = save(price, current_time, prices)
    Map.put(state, :prices, update_prices)
  end

  @spec save_order(Exchange.Order.order(), map) :: map
  def save_order(order, state) do
    ack_time = order.acknowledged_at
    {:ok, orders} = Map.fetch(state, :orders)
    update_orders = save(order, ack_time, orders)
    Map.put(state, :orders, update_orders)
  end

  @spec save_trade(trade :: Exchange.Trade, state :: map) :: map
  def save_trade(trade, state) do
    ack_time = trade.acknowledged_at
    {:ok, trades} = Map.fetch(state, :trades)
    update_trades = save(trade, ack_time, trades)
    Map.put(state, :trades, update_trades)
  end

  @spec cast_event(event :: atom, payload :: Exchange.Adapters.MessageBus.*()) ::
          Exchange.Adapters.MessageBus.*()
  def cast_event(event, payload) do
    send(:in_memory_time_series, {:cast_event, event, payload})
  end

  @spec get_state :: map
  def get_state do
    GenServer.call(:in_memory_time_series, :state)
  end

  def flush do
    GenServer.call(:in_memory_time_series, :flush)
  end

  defp message_bus do
    Application.get_env(:exchange, :message_bus_adapter)
  end

  @spec completed_trades_by_id(ticker :: atom, trader_id :: String.t()) :: [Exchange.Trade]
  def completed_trades_by_id(ticker, trader_id) do
    GenServer.call(:in_memory_time_series, {:trades_by_id, ticker, trader_id})
  end

  @spec completed_trades(ticker :: atom) :: [Exchange.Trade]
  def completed_trades(ticker) do
    {:ok, trades} = GenServer.call(:in_memory_time_series, {:completed_trades, ticker})
    trades
  end

  @spec get_live_orders(ticker :: atom) :: [Exchange.Order]
  def get_live_orders(ticker) do
    {:ok, orders} = GenServer.call(:in_memory_time_series, {:live_orders, ticker})
    orders
  end
end
