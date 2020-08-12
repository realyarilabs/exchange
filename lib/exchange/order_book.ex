defmodule Exchange.OrderBook do
  @moduledoc """
  # Order Book Struct

  The Order Book is the Exchange main data structure. It holds the Order Book
  in Memory where the MatchingEngine realizes the matches and register the Trades.

  Example of and Order Book for Physical Gold (AUX) in London Market
  Orders with currency in Great British Pounds:

  ```
      %Exchange.OrderBook{
        name: :AUXLND,
        currency: :GBP,
        buy: %{},
        sell: %{},
        order_ids: MapSet.new(),
        ask_min: 99_999,
        bid_max: 0,
        max_price: 99_999,
        min_price: 0
      }
  ```

  ## Buy and Sell Sides, price points and Orders

  The OrderBook has a buy and sell keys that represent each of the sides.

  Each side is a map indexed by an integer representing the `price_point`
  That contains a Queue of orders ordered by First In First Out (FIFO)

  The queues of Exchange.Order are implemented using Qex (an Elixir wrapper
  for the erlang OTP :queue.

  Example:
  ```
  buy: %{
    4001 => #Qex<[
      %Exchange.Order{
        acknowledged_at: ~U[2020-03-31 14:02:20.534364Z],
        modified_at: ~U[2020-03-31 14:02:20.534374Z],
        order_id: "e3fbecca-736d-11ea-b415-8c8590538575",
        price: 3970,
        side: :buy,
        size: 750,
        trader_id: "10995c7c-736e-11ea-a987-8c8590538575",
        type: :limit
      }
    ]>,
    4000 => #Qex<[ Exchange.Order(1), ... Exchange.Order(n) ]>,
    3980 => #Qex<[ Exchange.Order(1), ... Exchange.Order(n) ]>
  ```

  ## Other Attributes

  - name: Is the name of the ticker and the Id of the exchange. The exchange
  supports multiple matching engines identified by the different unique tickers.
  - currency: The currency that is supported inside this OrderBook.
  All orders must have prices in cents in that currency.
  - order_ids: Is an index of ids of the orders to see if and order is waiting
  for a match or not.

  These are all attributes that represent prices in cents for currency:
  - ask_min: is the current minimum ask price on the sell side.
  - bid_max: is the current maximum bid price on the buy side.
  - max_price: is the maximum price in cents that we accept a buy order
  - min_price: is the minimum price in cents that we accept a sell order
  """

  defstruct name: :AUXGBP,
            currency: :GBP,
            buy: %{},
            sell: %{},
            order_ids: Map.new(),
            expiration_list: [],
            expired_orders: [],
            completed_trades: [],
            ask_min: 99_999,
            bid_max: 1,
            max_price: 100_000,
            min_price: 0

  alias Exchange.{Order, OrderBook}

  @type ticker :: atom
  @type price_in_cents :: integer
  @type size_in_grams :: integer
  @type queue_of_orders :: %Qex{data: [Order.order()]}

  @type order_book :: %Exchange.OrderBook{
          name: atom,
          currency: atom,
          buy: %{optional(price_in_cents) => queue_of_orders},
          sell: %{optional(price_in_cents) => queue_of_orders},
          order_ids: %{optional(String.t()) => {atom, price_in_cents}},
          completed_trades: list,
          ask_min: price_in_cents,
          bid_max: price_in_cents,
          max_price: price_in_cents,
          min_price: price_in_cents
        }

  @doc """
  This is the core of the Matching Engine.
  Our Matching Engine implements the Price-Time Matching Algorithm.
  The first Orders arriving at that price point have priority.

  ## Parameters
    - order_book:
    - order:
  """
  @spec price_time_match(
          order_book :: Exchange.OrderBook.order_book(),
          order :: Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def price_time_match(
        %{bid_max: bid_max, ask_min: ask_min} = order_book,
        %Order{side: side, price: price, size: size} = order
      )
      when (price <= bid_max and side == :sell) or (price >= ask_min and side == :buy) do
    case fetch_matching_order(order_book, order) do
      :empty ->
        order_book
        |> queue_order(order)

      {:ok, matched_order} ->
        cond do
          matched_order.size == size ->
            order_book
            |> register_trade(order, matched_order)
            |> dequeue_order(matched_order)

          matched_order.size < size ->
            downsized_order = %{order | size: size - matched_order.size}

            order_book
            |> register_trade(order, matched_order)
            |> dequeue_order(matched_order)
            |> price_time_match(downsized_order)

          matched_order.size > size ->
            downsized_matched_order = %{matched_order | size: matched_order.size - size}

            order_book
            |> register_trade(order, matched_order)
            |> update_order(downsized_matched_order)
        end
    end
  end

  def price_time_match(
        %{bid_max: bid_max, ask_min: ask_min} = order_book,
        %Order{side: side, price: price} = order
      )
      when (price > bid_max and side == :sell) or
             (price < ask_min and side == :buy) do
    queue_order(order_book, order)
  end

  @doc """
  Generates a trade and adds it to the `completed_trades` of the order_book.

  ## Parameters
    - order_book: OrderBook that will store the trade
    - order: Newly placed order
    - matched_order: Existing order that matched the criteria of `order`
  """

  @spec register_trade(
          order_book :: Exchange.OrderBook.order_book(),
          order :: Exchange.Order.order(),
          matched_order :: Exchange.Order.order()
        ) :: Exchange.OrderBook.order_book()
  def register_trade(order_book, order, matched_order) do
    type =
      if order.initial_size <= matched_order.size do
        :full_fill
      else
        :partial_fill
      end

    new_trade = Exchange.Trade.generate_trade(order, matched_order, type)
    trades = order_book.completed_trades ++ [new_trade]

    %{order_book | completed_trades: trades}
  end

  @doc """
  Returns the list of completed trades.

  ## Parameters
    - order_book: OrderBook that stores the completed trades
  """
  @spec completed_trades(order_book :: Exchange.OrderBook.order_book()) :: [Exchange.Trade]
  def completed_trades(order_book) do
    order_book.completed_trades
  end

  @doc """
  Removes all the completed trades from the OrderBook.

  ## Parameters
    - order_book: OrderBook that stores the completed trades
  """
  @spec flush_trades!(order_book :: Exchange.OrderBook.order_book()) ::
          Exchange.OrderBook.order_book()
  def flush_trades!(order_book) do
    %{order_book | completed_trades: []}
  end

  @doc """
  Returns spread for this exchange by calculating the difference between `ask_min` and `bid_max`

  ## Parameters
    - order_book: OrderBook that stores the current state of a exchange
  """
  @spec spread(order_book :: Exchange.OrderBook.order_book()) :: number
  def spread(order_book) do
    order_book.ask_min - order_book.bid_max
  end

  @doc """
  Try to fetch a matching buy/sell at the current bid_max/ask_min price

  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` used to search a matching order
  """
  @spec fetch_matching_order(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          atom() | {atom(), Exchange.Order.order()}
  def fetch_matching_order(order_book, %Order{} = order) do
    price_points_queue =
      case order.side do
        :buy -> Map.get(order_book.sell, order_book.ask_min)
        :sell -> Map.get(order_book.buy, order_book.bid_max)
      end

    if price_points_queue == nil do
      :empty
    else
      matched_order =
        price_points_queue
        |> Enum.filter(fn order ->
          if is_integer(order.exp_time) do
            current_time = :os.system_time(:millisecond)

            if order.exp_time < current_time do
              false
            end
          end

          true
        end)
        |> List.first()

      case matched_order do
        nil -> :empty
        matched_order -> {:ok, matched_order}
      end
    end
  end

  @doc """
  Try to fetch a matching buy/sell with an order_id

  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` used to search an order
  """
  @spec fetch_order_by_id(order_book :: Exchange.OrderBook.order_book(), order_id :: String.t()) ::
          Order.order()
  def fetch_order_by_id(order_book, order_id) do
    index_of_order = Map.get(order_book.order_ids, order_id)

    if index_of_order do
      {side, price_point} = index_of_order

      orders_queue =
        order_book
        |> Map.get(side)
        |> Map.get(price_point)

      Enum.find(orders_queue, fn o ->
        o.order_id == order_id
      end)
    else
      nil
    end
  end

  @doc """
  Queues an `Exchange.Order` in to the correct price_point in the Order Book

  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` to be queued
  """
  @spec queue_order(
          order_book :: Exchange.OrderBook.order_book(),
          order :: Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def queue_order(order_book, %Order{} = order) do
    order_book
    |> insert_order_in_queue(order)
    |> add_order_to_index(order)
    |> add_order_to_expirations(order)
    |> set_bid_max(order)
    |> set_ask_min(order)
  end

  @doc """
  Removes an `Exchange.Order` from the Order Book
  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` to be removed
  """
  @spec dequeue_order(
          order_book :: Exchange.OrderBook.order_book(),
          order :: Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def dequeue_order(order_book, %Order{} = order) do
    dequeue_order_by_id(order_book, order.order_id)
  end

  @doc """
  Removes an `Exchange.Order` using its `order_id` from the Order Book
  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` to be removed
  """
  @spec dequeue_order_by_id(order_book :: Exchange.OrderBook.order_book(), order_id :: String.t()) ::
          Exchange.OrderBook.order_book()
  def dequeue_order_by_id(order_book, order_id) do
    {side, price_point} = Map.get(order_book.order_ids, order_id)

    orders_queue =
      order_book
      |> Map.get(side)
      |> Map.get(price_point)

    order_position =
      Enum.find_index(orders_queue, fn o ->
        o.order_id == order_id
      end)

    {q1, q2} = Qex.split(orders_queue, order_position)
    {poped_order, q2} = Qex.pop!(q2)
    new_queue = Qex.join(q1, q2)

    order_book
    |> update_queue(side, price_point, new_queue)
    |> remove_order_from_index(poped_order)
    |> calculate_min_max_prices(poped_order)
  end

  @doc """
  Updates an `Exchange.OrderBook.queue_of_orders()` from the Order Book

  ## Parameters
    - order_book: OrderBook that contains the active orders
    - side: The side of the queue
    - price_point: Key to get the queue
    - new_queue: Queue to be updated under the `price_point`
  """
  @spec update_queue(
          order_book :: Exchange.OrderBook.order_book(),
          side :: atom,
          price_point :: Exchange.OrderBook.price_in_cents(),
          new_queue :: Exchange.OrderBook.queue_of_orders()
        ) :: Exchange.OrderBook.order_book()
  def update_queue(order_book, side, price_point, new_queue) do
    len = Enum.count(new_queue)

    case len do
      0 ->
        updated_side_order_book =
          order_book
          |> Map.fetch!(side)
          |> Map.delete(price_point)

        Map.put(order_book, side, updated_side_order_book)

      _ ->
        updated_side_order_book =
          order_book
          |> Map.fetch!(side)
          |> Map.put(price_point, new_queue)

        Map.put(order_book, side, updated_side_order_book)
    end
  end

  @doc """
  Inserts an `Exchange.Order` in to the queue.
  The order is pushed to the end of the queue.

  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` to be inserted
  """
  @spec insert_order_in_queue(
          order_book :: Exchange.OrderBook.order_book(),
          order :: Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def insert_order_in_queue(order_book, order) do
    price_point = order.price()

    side_order_book = Map.fetch!(order_book, order.side)

    orders_queue =
      if Map.has_key?(side_order_book, price_point) do
        old_orders_queue = Map.get(side_order_book, price_point)
        Qex.push(old_orders_queue, order)
      else
        Qex.new([order])
      end

    side_order_book = Map.put(side_order_book, price_point, orders_queue)
    Map.put(order_book, order.side, side_order_book)
  end

  @doc """
  Updates an `Exchange.Order` in the Order Book
  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order: `Exchange.Order` to be updated
  """
  @spec update_order(
          order_book :: Exchange.OrderBook.order_book(),
          order :: Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def update_order(order_book, order) do
    price_point = order.price()

    side_order_book = Map.fetch!(order_book, order.side)

    orders_queue =
      if Map.has_key?(side_order_book, price_point) do
        old_orders_queue = Map.get(side_order_book, price_point)
        {{:value, _old}, orders_queue} = Qex.pop(old_orders_queue)
        # replace front with  the updated order
        Qex.push_front(orders_queue, order)
      else
        Qex.new([order])
      end

    side_order_book = Map.put(side_order_book, price_point, orders_queue)
    Map.put(order_book, order.side, side_order_book)
  end

  @doc """
  Updates the Order Book setting bid_max
  """
  @spec set_bid_max(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def set_bid_max(%OrderBook{bid_max: bid_max} = order_book, %Order{side: :buy, price: price})
      when bid_max < price do
    %{order_book | bid_max: price}
  end

  def set_bid_max(order_book, %Order{}), do: order_book

  @doc """
  Updates the Order Book setting ask_min
  """
  @spec set_ask_min(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def set_ask_min(%OrderBook{ask_min: ask_min} = order_book, %Order{side: :sell, price: price})
      when ask_min > price do
    %{order_book | ask_min: price}
  end

  def set_ask_min(order_book, %Order{}), do: order_book

  @doc """
  When an order is matched and removed from the order book the `ask_min` or `bid_max` must be updated.
  To update these values it is necessary to traverse the keys of the corresponding side of the Order Book, sort them and take the first element.
  When one of the sides is empty the value is set to `max_price - 1` or `min_price + 1` to the `ask_min` or `bid_max`, respectively.
  """
  @spec calculate_min_max_prices(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def calculate_min_max_prices(order_book, %Order{side: :sell}) do
    new_ask_min =
      order_book.sell
      |> Map.keys()
      |> Enum.sort()
      |> List.first()

    new_ask_min =
      case new_ask_min do
        nil -> order_book.max_price - 1
        _ -> new_ask_min
      end

    %{order_book | ask_min: new_ask_min}
  end

  def calculate_min_max_prices(order_book, %Order{side: :buy}) do
    new_bid_max =
      order_book.buy
      |> Map.keys()
      |> Enum.sort()
      |> Enum.reverse()
      |> List.first()

    new_bid_max =
      case new_bid_max do
        nil -> order_book.min_price + 1
        _ -> new_bid_max
      end

    %{order_book | bid_max: new_bid_max}
  end

  # OrderBook Index Management

  @doc """
  Verifies if an `Exchange.Order` with `order_id` exists in the Order Book

  ## Parameters
    - order_book: OrderBook that contains the active orders
    - order_id: Id to be searched in the `order_book`
  """
  @spec order_exists?(order_book :: Exchange.OrderBook.order_book(), order_id :: String.t()) ::
          boolean
  def order_exists?(order_book, order_id) do
    order_book.order_ids
    |> Map.keys()
    |> Enum.member?(order_id)
  end

  @doc """
  Periodic function that is triggered every second.
  This function is used to verify if there are expired orders.
  The expired orders are added to the `expired_orders`, removed from the `expiration_list` and removed from the sell or buy side.

  ## Parameters
    - order_book: OrderBook that contains the expired orders
  """
  @spec check_expired_orders!(order_book :: Exchange.OrderBook.order_book()) ::
          Exchange.OrderBook.order_book()
  def(check_expired_orders!(order_book)) do
    current_time = :os.system_time(:millisecond)

    order_book.expiration_list
    |> Enum.take_while(fn {ts, _id} -> ts < current_time end)
    |> Enum.map(fn {_ts, id} -> id end)
    |> Enum.reduce(order_book, fn order_id, order_book ->
      order_book
      |> update_expired_orders(order_id)
      |> pop_order_from_expiration
      |> dequeue_order_by_id(order_id)
    end)
  end

  @doc """
  Fetches the order with `order_id` and adds it to the Order Book's `expired_orders`

  ## Parameters
    - order_book: OrderBook that contains the `expired_orders`
  """
  @spec update_expired_orders(
          order_book :: Exchange.OrderBook.order_book(),
          order_id :: String.t()
        ) :: Exchange.OrderBook.order_book()
  def update_expired_orders(order_book, order_id) do
    order = fetch_order_by_id(order_book, order_id)
    %{order_book | expired_orders: order_book.expired_orders ++ [order]}
  end

  @doc """
  Flushes all the expired orders from the OrderBook's `expired_orders`

  ## Parameters
    - order_book: OrderBook that contains the `expired_orders`
  """
  @spec flush_expired_orders!(order_book :: Exchange.OrderBook.order_book()) ::
          Exchange.OrderBook.order_book()
  def flush_expired_orders!(order_book) do
    %{order_book | expired_orders: []}
  end

  @doc """
  Removes the first element from the OrderBook's `experiration_list`

  ## Parameters
    - order_book: OrderBook that contains the `experiration_list`
  """
  @spec pop_order_from_expiration(order_book :: Exchange.OrderBook.order_book()) ::
          Exchange.OrderBook.order_book()
  def pop_order_from_expiration(order_book) do
    [_pop | new_expiration_list] = order_book.expiration_list
    %{order_book | expiration_list: new_expiration_list}
  end

  @doc """
  Adds the expiring order to the Order Book's `expiration_list`, which is sorted by the `exp_time` afterwards.

  ## Parameters
    - order_book: OrderBook that contains the `expiration_list`
  """
  @spec add_order_to_expirations(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def add_order_to_expirations(order_book, %Order{exp_time: exp} = order)
      when is_integer(exp) and exp > 0 do
    new_expiration =
      (order_book.expiration_list ++ [{exp, order.order_id}])
      |> Enum.sort_by(fn {ts, _id} -> ts end)

    %{order_book | expiration_list: new_expiration}
  end

  def add_order_to_expirations(order_book, _order) do
    order_book
  end

  @doc """
  Adds the order to the Order Book's `order_ids`.
  The `order_ids` is used to have a better performance when searching for specific order.

  ## Parameters
    - order_book: OrderBook that contains the `order_ids`
  """
  @spec add_order_to_index(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def add_order_to_index(order_book, order) do
    idx = Map.put(order_book.order_ids, order.order_id, {order.side, order.price})
    Map.put(order_book, :order_ids, idx)
  end

  @doc """
  Removes the order to the Order Book's `order_ids`.

  ## Parameters
    - order_book: OrderBook that contains the `order_ids`
  """
  @spec remove_order_from_index(
          order_book :: Exchange.OrderBook.order_book(),
          Exchange.Order.order()
        ) ::
          Exchange.OrderBook.order_book()
  def remove_order_from_index(order_book, order) do
    Map.put(
      order_book,
      :order_ids,
      Map.delete(order_book.order_ids, order.order_id)
    )
  end

  @doc """
  Returns the sum of the size of all buy orders

  ## Parameters
    - order_book: OrderBook used to sum the size
  """
  @spec highest_ask_volume(order_book :: Exchange.OrderBook.order_book()) :: number
  def highest_ask_volume(order_book) do
    highest_volume(order_book.sell)
  end

  @spec highest_volume(Map.t()) :: number
  defp highest_volume(book) do
    book
    |> Enum.flat_map(fn {_k, v} -> v end)
    |> Enum.reduce(0, fn order, acc -> order.size + acc end)
  end

  @doc """
  Returns the sum of the size of all sell orders

  ## Parameters
    - order_book: OrderBook used to sum the size
  """
  @spec highest_bid_volume(order_book :: Exchange.OrderBook.order_book()) :: number
  def highest_bid_volume(order_book) do
    highest_volume(order_book.buy)
  end

  @spec total_orders(Exchange.OrderBook.queue_of_orders()) :: number
  defp total_orders(book) do
    book
    |> Enum.flat_map(fn {_k, v} -> v end)
    |> Enum.reduce(0, fn _order, acc -> 1 + acc end)
  end

  @doc """
  Returns the number of active buy orders.

  ## Parameters
    - order_book: OrderBook used to search the active orders
  """
  @spec total_bid_orders(order_book :: Exchange.OrderBook.order_book()) :: number
  def total_bid_orders(order_book) do
    total_orders(order_book.buy)
  end

  @doc """
  Returns the number of active sell orders.

  ## Parameters
    - order_book: OrderBook used to search the active orders
  """
  @spec total_ask_orders(order_book :: Exchange.OrderBook.order_book()) :: number
  def total_ask_orders(order_book) do
    total_orders(order_book.sell)
  end

  @doc """
  Returns the list of open orders

  ## Parameters
    - order_book: OrderBook used to search the active orders
  """
  @spec open_orders(order_book :: Exchange.OrderBook.order_book()) :: [Exchange.Order.order()]
  def open_orders(order_book) do
    open_sell_orders = orders_to_list(order_book.sell)
    open_buy_orders = orders_to_list(order_book.buy)

    open_sell_orders ++ open_buy_orders
  end

  @doc """
  Returns the list resulting of flattening a `Exchange.OrderBook.queue_of_orders()`

  ## Parameters
    - order_book: OrderBook used to search the active orders
  """
  @spec orders_to_list(Exchange.OrderBook.queue_of_orders()) :: [Exchange.Order.order()]
  def orders_to_list(orders) do
    orders
    |> Enum.flat_map(fn {_k, v} -> v end)
  end

  @doc """
  Returns the list of open orders from a trader by filtering the orders don't have `trader_id`

  ## Parameters
    - order_book: OrderBook used to search the orders
    - trader_id: The id that is used to filter orders
  """
  @spec open_orders_by_trader(
          order_book :: Exchange.OrderBook.order_book(),
          trader_id :: String.t()
        ) ::
          [
            Exchange.Order.order()
          ]
  def open_orders_by_trader(order_book, trader_id) do
    order_book
    |> open_orders()
    |> Enum.filter(fn order -> order.trader_id == trader_id end)
  end
end
