defmodule Exchange.Utils do
  @moduledoc """
  Auxiliary functions for Exchange APP
  """

  def fetch_completed_trades(ticker, trader_id) do
    time_series().completed_trades_by_id(ticker, trader_id)
    |> Enum.map(fn flux_trade ->
      trade = %Exchange.Trade{}

      %{
        trade
        | trade_id: flux_trade.fields.trade_id,
          ticker: String.to_atom(flux_trade.tags.ticker),
          currency: flux_trade.tags.currency,
          buyer_id: flux_trade.tags.buyer_id,
          seller_id: flux_trade.tags.seller_id,
          buy_order_id: flux_trade.fields.buy_order_id,
          sell_order_id: flux_trade.fields.sell_order_id,
          price: flux_trade.fields.price,
          size: flux_trade.fields.size,
          buy_init_size: flux_trade.fields.buy_init_size,
          sell_init_size: flux_trade.fields.sell_init_size,
          type: flux_trade.fields.type,
          acknowledged_at: flux_trade.fields.acknowledged_at
      }
    end)
  end

  def fetch_live_orders(ticker) do
    time_series().get_live_orders(ticker)
    |> Enum.map(fn o ->
      %Exchange.Order{
        order_id: o.fields.order_id,
        trader_id: o.fields.trader_id,
        price: o.fields.price,
        side: String.to_atom(o.tags.side),
        size: o.fields.size,
        exp_time: nil,
        type: String.to_atom(o.fields.type),
        modified_at: o.fields.modified_at,
        acknowledged_at: o.timestamp
      }
    end)
  end

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
      |> Enum.map(&%{&1 | acknowledged_at: :os.system_time(:nanosecond)})

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
      |> Enum.map(&%{&1 | acknowledged_at: :os.system_time(:nanosecond)})

    (buy_book ++ sell_book)
    |> Enum.each(fn order ->
      Exchange.MatchingEngine.place_limit_order(ticker, order)
    end)
  end

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
      |> Enum.map(&%{&1 | acknowledged_at: :os.system_time(:nanosecond)})

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
      |> Enum.map(&%{&1 | acknowledged_at: :os.system_time(:nanosecond)})

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

  def random_order(ticker \\ :AUXLND) do
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
      exp_time: nil,
      ticker: ticker,
      acknowledged_at: :os.system_time(:nanosecond)
    }
  end

  def generate_random_orders(n, ticker)
      when is_integer(n) and n > 0 do
    Enum.reduce(0..n, [], fn _n, acc ->
      [random_order(ticker) | acc]
    end)
  end

  def time_series do
    Application.get_env(:exchange, :time_series_adapter)
  end
end
