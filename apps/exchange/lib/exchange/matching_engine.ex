defmodule Exchange.MatchingEngine do
  @moduledoc """
  This is the core of the Exchange
  The matching engine is responsible for matching the orders on the order book
  """
  use GenServer

  alias Exchange.{Order, OrderBook}

  @type ticker :: atom

  require Logger
  # Client
  @check_expiration_rate 1_000

  def start_link(ticker: ticker, currency: currency, min_price: min_price, max_price: max_price)
      when is_atom(currency) and is_atom(ticker) and is_number(min_price) and is_number(max_price) do
    name = via_tuple(ticker)
    GenServer.start_link(__MODULE__, [ticker, currency, min_price, max_price], name: name)
  end

  @doc """
  Places an order on the matching engine identified by the ticker.

  The market order is set with the highest max_price for buying or the min_price for selling
  If there is sufficient liquidity on the order book the order is fullfilled
  otherwise the remaining unfulfilled order is put on the orderbook with the max/min price set
  """
  @spec place_market_order(ticker, Order.order()) :: atom
  def place_market_order(ticker, %Order{type: :market} = order) do
    GenServer.call(via_tuple(ticker), {:place_market_order, order})
  end

  @doc """
  Places a limit order on the matching engine identified by the ticker.
  If there is a match the order is fullfilled otherwise it enters
  the orderbook queue at the chosen price point
  """
  @spec place_limit_order(ticker, Order.order()) :: atom
  def place_limit_order(ticker, %Order{type: :limit, price: price, size: size} = order)
      when price > 0 and size > 0 do
    GenServer.call(via_tuple(ticker), {:place_limit_order, order})
  end

  @doc """
  Cancels an order and removes it from the Order Book
  """
  @spec cancel_order(ticker, String.t()) :: atom
  def cancel_order(ticker, order_id) do
    GenServer.call(via_tuple(ticker), {:cancel_order, order_id})
  end

  @doc """
  Returns the current Order Book
  """
  @spec order_book_entries(ticker) :: {atom, OrderBook.order_book()}
  def order_book_entries(ticker) do
    GenServer.call(via_tuple(ticker), {:order_book_entries})
  end

  @doc """
  Returns the current maximum biding price
  """
  @spec bid_max(ticker) :: {atom, number}
  def bid_max(ticker) do
    GenServer.call(via_tuple(ticker), :bid_max)
  end

  @doc """
  Returns the current minimum asking price
  """
  @spec ask_min(ticker) :: {atom, number}
  def ask_min(ticker) do
    GenServer.call(via_tuple(ticker), :ask_min)
  end

  @doc """
  Returns the current Spread
  """
  @spec ask_min(ticker) :: {atom, number}
  def spread(ticker) do
    GenServer.call(via_tuple(ticker), :spread)
  end

  @doc """
  Returns the current highest asking volume
  """
  @spec ask_volume(ticker) :: {atom, number}
  def ask_volume(ticker) do
    GenServer.call(via_tuple(ticker), :ask_volume)
  end

  defp via_tuple(ticker) do
    {:via, Registry, {:matching_engine_registry, ticker}}
  end

  # Server

  def init([ticker, currency, min_price, max_price]) do
    order_book = %Exchange.OrderBook{
      name: ticker,
      currency: currency,
      buy: %{},
      sell: %{},
      order_ids: Map.new(),
      expiration_list: [],
      completed_trades: [],
      expired_orders: [],
      ask_min: max_price,
      bid_max: 0,
      max_price: max_price,
      min_price: min_price || 0
    }

    order_book = order_book_restore!(order_book)

    Process.send_after(self(), :check_expiration, @check_expiration_rate)
    {:ok, order_book}
  end

  def order_book_restore!(order_book) do
    open_orders = Exchange.Utils.fetch_live_orders(order_book.name)

    if Enum.count(open_orders) > 0 do
      open_orders
      |> Enum.reduce(order_book, fn order, order_book ->
        OrderBook.price_time_match(order_book, order)
      end)
    else
      order_book
    end
  end

  def handle_info(:check_expiration, order_book) do
    order_book = OrderBook.check_expired_orders!(order_book)

    if Enum.count(order_book.expired_orders) > 0 do
      Enum.each(
        order_book.expired_orders,
        fn order ->
          EventBus.cast_event(:order_expired, %EventBus.OrderExpired{order: order})
        end
      )
    end

    order_book = OrderBook.flush_expired_orders!(order_book)
    Process.send_after(self(), :check_expiration, @check_expiration_rate)

    {:noreply, order_book}
  end

  def handle_call(:ask_min, _from, order_book) do
    ask_min =
      order_book.ask_min
      |> Money.new(order_book.currency)

    {:reply, {:ok, ask_min}, order_book}
  end

  def handle_call(:bid_max, _from, order_book) do
    bid_max =
      order_book.bid_max
      |> Money.new(order_book.currency)

    {:reply, {:ok, bid_max}, order_book}
  end

  def handle_call(:ask_volume, _from, order_book) do
    ask_volume = Exchange.OrderBook.highest_ask_volume(order_book)
    {:reply, {:ok, ask_volume}, order_book}
  end

  def handle_call(:spread, _from, order_book) do
    spread =
      OrderBook.spread(order_book)
      |> Money.new(order_book.currency)

    {:reply, {:ok, spread}, order_book}
  end

  def handle_call({:place_market_order, order}, _from, order_book) do
    if OrderBook.order_exists?(order_book, order.order_id) do
      {:reply, :error, order_book}
    else
      order =
        if order.side == :buy do
          order |> Map.put(:price, order_book.max_price)
        else
          order |> Map.put(:price, order_book.min_price)
        end

      EventBus.cast_event(:order_queued, %EventBus.OrderQueued{order: order})

      order_book =
        order_book
        |> OrderBook.price_time_match(order)
        |> broadcast_trades!

      {:reply, :ok, order_book}
    end
  end

  def handle_call({:place_limit_order, order}, _from, order_book) do
    if OrderBook.order_exists?(order_book, order.order_id) do
      {:reply, :error, order_book}
    else
      EventBus.cast_event(:order_queued, %EventBus.OrderQueued{order: order})

      order_book =
        order_book
        |> OrderBook.price_time_match(order)
        |> broadcast_trades!

      {:reply, :ok, order_book}
    end
  end

  def handle_call({:order_book_entries}, _from, order_book) do
    {:reply, {:ok, order_book}, order_book}
  end

  def handle_call({:cancel_order, order_id}, _from, order_book) do
    if OrderBook.order_exists?(order_book, order_id) do
      cancelled_order = OrderBook.fetch_order_by_id(order_book, order_id)
      order_book = OrderBook.dequeue_order_by_id(order_book, order_id)
      EventBus.cast_event(:order_cancelled, %EventBus.OrderCancelled{order: cancelled_order})

      {:reply, :ok, order_book}
    else
      {:reply, :error, order_book}
    end
  end

  defp broadcast_trades!(order_book) do
    trades = OrderBook.completed_trades(order_book)

    if Enum.count(trades) > 0 do
      trades
      |> Enum.each(fn t ->
        EventBus.cast_event(:trade_executed, %EventBus.TradeExecuted{trade: t})
      end)

      OrderBook.flush_trades!(order_book)
    else
      order_book
    end
  end
end
