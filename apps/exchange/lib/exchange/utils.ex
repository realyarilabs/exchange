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
end
