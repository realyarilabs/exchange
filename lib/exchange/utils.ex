defmodule Exchange.Utils do
  @moduledoc """
  Auxiliary functions for Exchange APP
  """

  @doc """
  Fetches the completed trades stored by a `Exchange.TimeSeries` adapter given a ticker and a id

  ## Parameters
    - ticker: Market where the fetch should be made
    - trader_id: The that a given trade must match
  """
  @spec fetch_completed_trades(ticker :: atom, trader_id :: String.t()) :: list
  def fetch_completed_trades(ticker, trader_id) do
    time_series().completed_trades_by_id(ticker, trader_id)
  end

  @doc """
  Fetches the completed trades stored by a `Exchange.TimeSeries` adapter given a ticker and a id

  ## Parameters
    - ticker: Market where the fetch should be made
    - trader_id: The that a given trade must match
  """
  @spec fetch_all_completed_trades(ticker :: atom) :: list
  def fetch_all_completed_trades(ticker) do
    time_series().completed_trades(ticker)
  end

  @doc """
  Fetches the completed stored by a `Exchange.TimeSeries` adapter given a ticker and a trade id.

  ## Parameters
    - ticker: Market where the fetch should be made
    - trade_id: Id of the requested trade
  """
  @spec fetch_completed_trade_by_trade_id(ticker :: atom, trade_id :: String.t()) ::
          Exchange.Trade
  def fetch_completed_trade_by_trade_id(ticker, trade_id) do
    time_series().get_completed_trade_by_trade_id(ticker, trade_id)
  end

  @doc """
  Fetches the active orders stored by a `Exchange.TimeSeries` adapter given a ticker

  ## Parameters
    - ticker: Market where the fetch should be made
  """
  @spec fetch_live_orders(ticker :: atom) :: list
  def fetch_live_orders(ticker) do
    time_series().get_live_orders(ticker)
  end

  @doc """
  Prints an `Exchange.OrderBook`
  """
  @spec print_order_book(order_book :: Exchange.OrderBook.order_book()) :: :ok
  def print_order_book(order_book) do
    IO.puts("----------------------------")
    IO.puts(" Price Level | ID | Size ")
    IO.puts("----------------------------")

    order_book.buy
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.each(fn price_point ->
      IO.puts(price_point)

      Map.get(order_book.buy, price_point)
      |> Enum.each(fn order ->
        IO.puts("          #{order.order_id}, #{order.size}")
      end)
    end)

    IO.puts("----------------------------")
    IO.puts(" Sell side | ID | Size ")
    IO.puts("----------------------------")

    order_book.sell
    |> Map.keys()
    |> Enum.sort()
    |> Enum.each(fn price_point ->
      IO.puts(price_point)

      Map.get(order_book.sell, price_point)
      |> Enum.each(fn order ->
        IO.puts("           #{order.order_id}, #{order.size}")
      end)
    end)
  end

  @doc """
  Return a empty `Exchange.OrderBook`
  """
  @spec empty_order_book :: Exchange.OrderBook.order_book()
  def empty_order_book do
    %Exchange.OrderBook{
      name: :AUXLND,
      currency: :GBP,
      buy: %{},
      sell: %{},
      order_ids: Map.new(),
      completed_trades: [],
      ask_min: 99_999,
      bid_max: 1,
      max_price: 100_000,
      min_price: 0
    }
  end

  @doc """
  Creates a limit order for a given ticker
  """
  @spec sample_order(map) :: Exchange.Order.order()
  def sample_order(%{size: z, price: p, side: s}) do
    %Exchange.Order{
      type: :limit,
      order_id: "9",
      trader_id: "alchemist9",
      side: s,
      initial_size: z,
      size: z,
      price: p
    }
  end

  @doc """
  Creates a expiring limit order for a given ticker

  """
  @spec sample_expiring_order(%{
          price: number,
          side: atom,
          size: number,
          exp_time: number,
          id: String.t()
        }) ::
          Exchange.Order.order()
  def sample_expiring_order(%{size: z, price: p, side: s, id: id, exp_time: t}) do
    %Exchange.Order{
      type: :limit,
      order_id: id,
      trader_id: "test_user_1",
      side: s,
      initial_size: z,
      size: z,
      price: p,
      exp_time: t
    }
  end

  @doc """
  This function places sample buy orders and sell orders in the correct market using the ticker.
  ## Arguments
    - ticker: Market where the orders should be placed
  """
  @spec sample_matching_engine_init(ticker :: atom) :: :ok
  def sample_matching_engine_init(ticker) do
    buy_book =
      [
        %Exchange.Order{
          type: :limit,
          order_id: "4",
          trader_id: "alchemist1",
          side: :buy,
          initial_size: 250,
          size: 250,
          price: 4000
        },
        %Exchange.Order{
          type: :limit,
          order_id: "6",
          trader_id: "alchemist2",
          side: :buy,
          initial_size: 500,
          size: 500,
          price: 4000
        },
        %Exchange.Order{
          type: :limit,
          order_id: "2",
          trader_id: "alchemist3",
          side: :buy,
          initial_size: 750,
          size: 750,
          price: 3970
        },
        %Exchange.Order{
          type: :limit,
          order_id: "7",
          trader_id: "alchemist4",
          side: :buy,
          initial_size: 150,
          size: 150,
          price: 3960
        }
      ]
      |> Enum.map(&%{&1 | acknowledged_at: DateTime.utc_now() |> DateTime.to_unix(:nanosecond)})

    sell_book =
      [
        %Exchange.Order{
          type: :limit,
          order_id: "1",
          trader_id: "alchemist5",
          side: :sell,
          initial_size: 750,
          size: 750,
          price: 4010
        },
        %Exchange.Order{
          type: :limit,
          order_id: "5",
          trader_id: "alchemist6",
          side: :sell,
          initial_size: 500,
          size: 500,
          price: 4010
        },
        %Exchange.Order{
          type: :limit,
          order_id: "8",
          trader_id: "alchemist7",
          side: :sell,
          initial_size: 750,
          size: 750,
          price: 4010
        },
        %Exchange.Order{
          type: :limit,
          order_id: "3",
          trader_id: "alchemist8",
          side: :sell,
          initial_size: 250,
          size: 250,
          price: 4020
        }
      ]
      |> Enum.map(&%{&1 | acknowledged_at: DateTime.utc_now() |> DateTime.to_unix(:nanosecond)})

    (buy_book ++ sell_book)
    |> Enum.each(fn order ->
      Exchange.MatchingEngine.place_limit_order(ticker, order)
    end)
  end

  @doc """
  Creates an `Exchange.OrderBook` with sample buy and sell orders

  ## Arguments
    - ticker: Market where the order book belongs
  """
  @spec sample_order_book(ticker :: atom) :: Exchange.OrderBook.order_book()
  def sample_order_book(ticker) do
    buy_book =
      [
        %Exchange.Order{
          type: :limit,
          order_id: "4",
          trader_id: "alchemist1",
          side: :buy,
          initial_size: 250,
          size: 250,
          ticker: ticker,
          price: 4000
        },
        %Exchange.Order{
          type: :limit,
          order_id: "6",
          trader_id: "alchemist2",
          side: :buy,
          initial_size: 500,
          size: 500,
          ticker: ticker,
          price: 4000
        },
        %Exchange.Order{
          type: :limit,
          order_id: "2",
          trader_id: "alchemist3",
          side: :buy,
          initial_size: 750,
          size: 750,
          ticker: ticker,
          price: 3970
        },
        %Exchange.Order{
          type: :limit,
          order_id: "7",
          trader_id: "alchemist4",
          side: :buy,
          initial_size: 150,
          size: 150,
          ticker: ticker,
          price: 3960
        }
      ]
      |> Enum.map(&%{&1 | acknowledged_at: DateTime.utc_now() |> DateTime.to_unix(:nanosecond)})

    sell_book =
      [
        %Exchange.Order{
          type: :limit,
          order_id: "1",
          trader_id: "alchemist5",
          side: :sell,
          initial_size: 750,
          size: 750,
          ticker: ticker,
          price: 4010
        },
        %Exchange.Order{
          type: :limit,
          order_id: "5",
          trader_id: "alchemist6",
          side: :sell,
          initial_size: 500,
          size: 500,
          ticker: ticker,
          price: 4010
        },
        %Exchange.Order{
          type: :limit,
          order_id: "8",
          trader_id: "alchemist7",
          side: :sell,
          initial_size: 750,
          size: 750,
          ticker: ticker,
          price: 4010
        },
        %Exchange.Order{
          type: :limit,
          order_id: "3",
          trader_id: "alchemist8",
          side: :sell,
          initial_size: 250,
          size: 250,
          ticker: ticker,
          price: 4020
        }
      ]
      |> Enum.map(&%{&1 | acknowledged_at: DateTime.utc_now() |> DateTime.to_unix(:nanosecond)})

    order_book = %Exchange.OrderBook{
      name: ticker,
      currency: :GBP,
      buy: %{},
      sell: %{},
      order_ids: Map.new(),
      completed_trades: [],
      ask_min: 99_999,
      bid_max: 1001,
      max_price: 100_000,
      min_price: 1000
    }

    (buy_book ++ sell_book)
    |> Enum.reduce(order_book, fn order, order_book ->
      Exchange.OrderBook.price_time_match(order_book, order)
    end)
  end

  @doc """
  Creates a random order for a given ticker

  ## Arguments
    - ticker: Market where the order should be placed
  """
  @spec random_order(ticker :: atom) :: Exchange.Order.order()
  def random_order(ticker) do
    trader_id = "alchemist" <> Integer.to_string(Enum.random(0..9))
    side = Enum.random([:buy, :sell])
    type = Enum.random([:market, :limit, :marketable_limit])
    price = 0..10 |> Enum.map(fn x -> 2000 + x * 200 end) |> Enum.random()
    size = 0..10 |> Enum.map(fn x -> 1000 + x * 500 end) |> Enum.random()
    order_id = UUID.uuid1()

    %Exchange.Order{
      order_id: order_id,
      trader_id: trader_id,
      side: side,
      price: price,
      initial_size: size,
      size: size,
      type: type,
      exp_time: :os.system_time(:millisecond),
      ticker: ticker,
      acknowledged_at: :os.system_time(:nanosecond)
    }
  end

  @doc """
  Function that generates n random orders given a specific ticker
  ## Arguments
    - ticker: Market where the order should be placed
    - n: Number of orders to be generated
  """
  @spec generate_random_orders(n :: number, ticker :: atom) :: [Exchange.Order.order()]
  def generate_random_orders(n, ticker)
      when is_integer(n) and n > 0 do
    Enum.reduce(0..n, [], fn _n, acc ->
      [random_order(ticker) | acc]
    end)
  end

  @doc """
  Retrieves the module of an adapter of `Exchange.TimeSeries`
  """
  @spec time_series :: any
  def time_series do
    Application.get_env(:exchange, :time_series_adapter)
  end
end
