list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

buy_order = %Exchange.Order{
  type: :limit,
  order_id: UUID.uuid1(),
  trader_id: UUID.uuid1(),
  side: :buy,
  size: 250,
  price: 4000 + round(:rand.uniform * 100)}

sell_order = %Exchange.Order{
  type: :limit,
  order_id: UUID.uuid1(),
  trader_id: UUID.uuid1(),
  side: :sell,
  size: 250,
  price: 4000 + round(:rand.uniform * 100)}

buy_order_params = %{
  type: :limit,
  order_id: UUID.uuid1(),
  trader_id: UUID.uuid1(),
  side: :buy,
  size: 250,
  price: 4000}

sell_order_params = %{
  type: :limit,
  order_id: UUID.uuid1(),
  trader_id: UUID.uuid1(),
  side: :sell,
  size: 250,
  price: 4010}

sell_order_for_trade_params = %{
  type: :limit,
  order_id: UUID.uuid1(),
  trader_id: UUID.uuid1(),
  side: :sell,
  size: 250,
  price: 4000}

# Benchee.run(%{
#   "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
#   "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
# })

Benchee.run(%{
  "place_limit_buy_order_on_ME" => fn ->
      Exchange.MatchingEngine.place_limit_order(:AUXLND, buy_order)
  end,
  "place_limit_sell_order_ME" => fn ->
      Exchange.MatchingEngine.place_limit_order(:AUXLND, sell_order)
  end
})

Benchee.run(%{
  "place_limit_buy_order_external_trades" => fn ->
      Exchange.place_order(buy_order_params)
  end,
  "place_limit_sell_order_external_trades" => fn ->
      Exchange.place_order(sell_order_params)
  end
})

Benchee.run(%{
  "place_limit_buy_order_external" => fn ->
      Exchange.place_order(buy_order_params)
  end,
  "place_limit_sell_order_for_trades" => fn ->
      Exchange.place_order(sell_order_for_trade_params)
  end
})
