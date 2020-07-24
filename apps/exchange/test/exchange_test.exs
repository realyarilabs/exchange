defmodule ExchangeTest do
  use ExUnit.Case
  doctest Exchange

  test "accepts orders" do
    buy_limit_order = %{
      order_id: UUID.uuid1(),
      trader_id: UUID.uuid1(),
      side: :buy,
      size: 2000,
      price: 4030,
      type: :limit
    }

    assert Exchange.place_order(buy_limit_order, :AUXLND) == :ok
  end
end
