insert_into_exchange = fn orders, order_book ->
  orders
  |> Enum.reduce(order_book, fn order, ob ->
    type =
      case order.type do
        :market -> :place_market_order
        :limit -> :place_limit_order
      end

    {:reply, :ok, nob} = Exchange.MatchingEngine.handle_call({type, order}, nil, ob)
    nob
  end)
end

small = Exchange.Utils.generate_random_orders(1_000)
medium = Exchange.Utils.generate_random_orders(10_000)
big = Exchange.Utils.generate_random_orders(100_000)

small_ob = %Exchange.OrderBook{
  name: :AUXLND,
  currency: :gbp,
  buy: %{},
  sell: %{},
  order_ids: Map.new(),
  completed_trades: [],
  ask_min: 99_999,
  bid_max: 0,
  max_price: 100_000,
  min_price: 0
}

medium_ob = %Exchange.OrderBook{
  name: :AUXLND,
  currency: :gbp,
  buy: %{},
  sell: %{},
  order_ids: Map.new(),
  completed_trades: [],
  ask_min: 99_999,
  bid_max: 0,
  max_price: 100_000,
  min_price: 0
}

big_ob = %Exchange.OrderBook{
  name: :AUXLND,
  currency: :gbp,
  buy: %{},
  sell: %{},
  order_ids: Map.new(),
  completed_trades: [],
  ask_min: 99_999,
  bid_max: 0,
  max_price: 100_000,
  min_price: 0
}

Benchee.run(
  %{
    "1000 orders" => fn -> insert_into_exchange.(small, small_ob) end,
    "10000 orders" => fn -> insert_into_exchange.(medium, medium_ob) end,
    "100000 orders" => fn -> insert_into_exchange.(big, big_ob) end
  },
  print: %{
    benchmarking: true,
    fast_warning: false,
    configuration: true
  },
  formatters: [
    {Benchee.Formatters.HTML, file: "benchmark/v1.html"},
    {Benchee.Formatters.Console, extended_statistics: true}
  ],
  unit_scaling: :smallest,
  memory_time: 5
)
