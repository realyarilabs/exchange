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
  @price_broadcast_rate 1_000

  def start_link(ticker: ticker, currency: currency, min_price: min_price, max_price: max_price)
      when is_atom(currency) and is_atom(ticker) and is_number(min_price) and is_number(max_price) do
    name = via_tuple(ticker)
    GenServer.start_link(__MODULE__, [ticker, currency, min_price, max_price], name: name)
  end

  @doc """
  Places an order on the matching engine identified by the ticker.
  ## Market Order
    The market order is set with the highest max_price for buying or the min_price for selling
    If there is sufficient liquidity on the order book the order is fullfilled
    otherwise the remaining unfulfilled order is put on the orderbook with the max/min price set
  ## Limit Order
    Places a limit order on the matching engine identified by the ticker.
    If there is a match the order is fullfilled otherwise it enters
    the orderbook queue at the chosen price point
  ## Marketable Limit Order
    Places a marketable limit order on the matching engine identified by the ticker.
    The price of this order's price point is set with the min price (ask_min) if it
    is a buy order or with the max price(bid_max) if it is a sell order.
    If there is a match the order is fullfilled otherwise it enters
    the orderbook queue at the chosen price point
  ## Stop Loss Order

  """
  @spec place_order(ticker, Order.order()) :: atom
  def place_order(ticker, order) do
    GenServer.call(via_tuple(ticker), {:place_order, order})
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
    GenServer.call(via_tuple(ticker), :order_book_entries)
  end

  @doc """
  Returns the current maximum biding price
  """
  @spec bid_max(ticker) :: {atom, Money}
  def bid_max(ticker) do
    GenServer.call(via_tuple(ticker), :bid_max)
  end

  @doc """
  Returns the current maximum biding price
  """
  @spec bid_volume(ticker) :: {atom, number}
  def bid_volume(ticker) do
    GenServer.call(via_tuple(ticker), :bid_volume)
  end

  @doc """
  Returns the current minimum asking price
  """
  @spec ask_min(ticker) :: {atom, Money}
  def ask_min(ticker) do
    GenServer.call(via_tuple(ticker), :ask_min)
  end

  @doc """
  Returns the current Spread
  """
  @spec spread(ticker) :: {atom, Money}
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

  @doc """
  Returns the number of open buy orders
  """
  @spec total_bid_orders(ticker) :: {atom, number}
  def total_bid_orders(ticker) do
    GenServer.call(via_tuple(ticker), :total_bid_orders)
  end

  @doc """
  Returns the number of open sell orders
  """
  @spec total_ask_orders(ticker) :: {atom, number}
  def total_ask_orders(ticker) do
    GenServer.call(via_tuple(ticker), :total_ask_orders)
  end

  @doc """
  Returns the list of open orders
  """
  @spec open_orders(ticker) :: {atom, list()}
  def open_orders(ticker) do
    GenServer.call(via_tuple(ticker), :open_orders)
  end

  @doc """
  Returns the list of open orders from a trader
  """
  @spec open_orders_by_trader(ticker, String.t()) :: {atom, list()}
  def open_orders_by_trader(ticker, trader_id) do
    GenServer.call(via_tuple(ticker), {:open_orders_by_trader, trader_id})
  end

  @doc """
  Returns the open order from a order_id
  """
  @spec open_order_by_id(ticker, String.t()) :: {atom, Exchange.Order.order()}
  def open_order_by_id(ticker, order_id) do
    GenServer.call(via_tuple(ticker), {:open_order_by_id, order_id})
  end

  @doc """
  Returns the open order from a order_id
  """
  @spec last_price(ticker :: atom, side :: atom) :: {atom, number}
  def last_price(ticker, side) do
    GenServer.call(via_tuple(ticker), {:last_price, side})
  end

  @doc """
  Returns the open order from a order_id
  """
  @spec last_size(ticker :: atom, side :: atom) :: {atom, number}
  def last_size(ticker, side) do
    GenServer.call(via_tuple(ticker), {:last_size, side})
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
      ask_min: max_price - 1,
      bid_max: min_price + 1,
      max_price: max_price,
      min_price: min_price
    }

    order_book = order_book_restore!(order_book)

    Process.send_after(self(), :check_expiration, @check_expiration_rate)
    Process.send_after(self(), :price_broadcast, @price_broadcast_rate)
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

  def handle_info(:check_stop_loss, order_book) do
    order_book = OrderBook.stop_loss_activation(order_book) |> broadcast_trades!()
    {:noreply, order_book}
  end

  def handle_info(:price_broadcast, order_book) do
    price_info = %Exchange.Adapters.MessageBus.PriceBroadcast{
      ticker: order_book.name,
      ask_min: order_book.ask_min,
      bid_max: order_book.bid_max
    }

    message_bus().cast_event(:price_broadcast, price_info)
    Process.send_after(self(), :price_broadcast, @price_broadcast_rate)
    {:noreply, order_book}
  end

  def handle_info(:check_expiration, order_book) do
    order_book = OrderBook.check_expired_orders!(order_book)

    if Enum.count(order_book.expired_orders) > 0 do
      Enum.each(
        order_book.expired_orders,
        fn order ->
          message_bus().cast_event(:order_expired, %Exchange.Adapters.MessageBus.OrderExpired{
            order: order
          })
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

  def handle_call(:bid_volume, _from, order_book) do
    bid_volume = Exchange.OrderBook.highest_bid_volume(order_book)
    {:reply, {:ok, bid_volume}, order_book}
  end

  def handle_call(:open_orders, _from, order_book) do
    open_orders = Exchange.OrderBook.open_orders(order_book)

    {:reply, {:ok, open_orders}, order_book}
  end

  def handle_call({:open_orders_by_trader, trader_id}, _from, order_book) do
    open_orders_by_trader = Exchange.OrderBook.open_orders_by_trader(order_book, trader_id)

    {:reply, {:ok, open_orders_by_trader}, order_book}
  end

  def handle_call({:open_order_by_id, order_id}, _from, order_book) do
    order = Exchange.OrderBook.fetch_order_by_id(order_book, order_id)
    {:reply, {:ok, order}, order_book}
  end

  def handle_call(:spread, _from, order_book) do
    spread =
      OrderBook.spread(order_book)
      |> Money.new(order_book.currency)

    {:reply, {:ok, spread}, order_book}
  end

  def handle_call({:place_order, %Order{} = order}, _from, order_book) do
    if OrderBook.order_exists?(order_book, order.order_id) do
      {:reply, :error, order_book}
    else
      order = Order.assign_prices(order, order_book)
      validity = Order.validate_price(order, order_book)

      case validity do
        :ok ->
          message_bus().cast_event(:order_queued, %Exchange.Adapters.MessageBus.OrderQueued{
            order: order
          })

          order_book =
            order_book
            |> OrderBook.price_time_match(order)
            |> broadcast_trades!

          send(self(), :check_stop_loss)

          {:reply, :ok, order_book}

        {:error, cause} ->
          {:reply, {:error, cause}, order_book}
      end
    end
  end

  def handle_call(:order_book_entries, _from, order_book) do
    {:reply, {:ok, order_book}, order_book}
  end

  def handle_call({:cancel_order, order_id}, _from, order_book) do
    if OrderBook.order_exists?(order_book, order_id) do
      cancelled_order = OrderBook.fetch_order_by_id(order_book, order_id)

      current_time = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      if (is_integer(cancelled_order.exp_time) and
            cancelled_order.exp_time < current_time) or !is_integer(cancelled_order.exp_time) do
        order_book = OrderBook.dequeue_order_by_id(order_book, order_id)

        message_bus().cast_event(:order_cancelled, %Exchange.Adapters.MessageBus.OrderCancelled{
          order: cancelled_order
        })

        {:reply, :ok, order_book}
      else
        {:reply, :error, order_book}
      end
    else
      {:reply, :error, order_book}
    end
  end

  def handle_call(:total_bid_orders, _from, order_book) do
    total_bid_orders = Exchange.OrderBook.total_bid_orders(order_book)
    {:reply, {:ok, total_bid_orders}, order_book}
  end

  def handle_call(:total_ask_orders, _from, order_book) do
    total_ask_orders = Exchange.OrderBook.total_ask_orders(order_book)
    {:reply, {:ok, total_ask_orders}, order_book}
  end

  def handle_call({:last_price, side}, _from, order_book) do
    price = Exchange.OrderBook.last_price(order_book, side)
    {:reply, {:ok, price}, order_book}
  end

  def handle_call({:last_size, side}, _from, order_book) do
    size = Exchange.OrderBook.last_size(order_book, side)
    {:reply, {:ok, size}, order_book}
  end

  defp broadcast_trades!(order_book) do
    trades = OrderBook.completed_trades(order_book)

    if Enum.count(trades) > 0 do
      trades
      |> Enum.each(fn t ->
        message_bus().cast_event(:trade_executed, %Exchange.Adapters.MessageBus.TradeExecuted{
          trade: t
        })
      end)

      OrderBook.flush_trades!(order_book)
    else
      order_book
    end
  end

  defp message_bus do
    Application.get_env(:exchange, :message_bus_adapter, Exchange.Adapters.EventBus)
  end
end
