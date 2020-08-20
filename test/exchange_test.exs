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
      type: :limit,
      ticker: :TEST1
    }

    assert Exchange.place_order(buy_limit_order, :TEST1) == :ok
  end

  describe "Multi ticker" do
    setup _context do
      {:ok, %{config: Application.get_env(:exchange, :tickers, [])}}
    end

    test "Check if the configurated tickers are up", %{config: config} do
      pids =
        config
        |> Enum.map(fn {id, _currency, _min_price, _max_price} ->
          GenServer.whereis({:via, Registry, {:matching_engine_registry, id}})
        end)
        |> Enum.filter(fn p_id -> p_id == nil end)

      assert pids == []
    end
  end
end
