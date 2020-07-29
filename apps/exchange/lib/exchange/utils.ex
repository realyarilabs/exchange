defmodule Exchange.Utils do
  @moduledoc """
  Auxiliary functions for Exchange APP
  """

  def fetch_live_orders(ticker) do
    Flux.Orders.get_live_orders(ticker)
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

  def random_order do
    trader_id = "alchemist" <> Integer.to_string(Enum.random(0..9))
    side = Enum.random([:buy, :sell])
    type = Enum.random([:market, :limit])
    price = 0..10 |> Enum.map(fn x -> 2000 + x * 200 end) |> Enum.random()
    size = 0..10 |> Enum.map(fn x -> 1000 + x * 500 end) |> Enum.random()
    order_id = UUID.uuid1
    %Exchange.Order{
      order_id: order_id,
      trader_id: trader_id,
      side: side,
      price: price,
      initial_size: size,
      size: size,
      type: type,
      exp_time: nil,
      acknowledged_at: :os.system_time(:nanosecond)
    }
  end

  def generate_random_orders(n)
  when is_integer(n) and n > 0 do
    Enum.reduce(0..n, [], fn _n, acc ->
      [random_order() | acc]
    end)
  end
end
