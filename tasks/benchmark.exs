insert_into_exchange = fn orders ->
  orders
  |> Enum.each(fn order ->
    case order.type do
      :market ->
        Exchange.MatchingEngine.place_market_order(order.ticker, order)

      :limit ->
        Exchange.MatchingEngine.place_limit_order(order.ticker, order)

      :marketable_limit ->
        Exchange.MatchingEngine.place_marketable_limit_order(order.ticker, order)
    end
  end)
end

aux_small = Exchange.Utils.generate_random_orders(1_000, :AUXLND)
aux_medium = Exchange.Utils.generate_random_orders(10_000, :AUXLND)
aux_big = Exchange.Utils.generate_random_orders(100_000, :AUXLND)
ag_small = Exchange.Utils.generate_random_orders(1_000, :AGUS)
ag_medium = Exchange.Utils.generate_random_orders(10_000, :AGUS)
ag_big = Exchange.Utils.generate_random_orders(100_000, :AGUS)
mix_small = Enum.shuffle(aux_small ++ ag_small)
mix_medium = Enum.shuffle(aux_medium ++ ag_medium)
mix_big = Enum.shuffle(aux_big ++ ag_big)

Benchee.run(
  %{
    "1000 orders" => fn -> insert_into_exchange.(aux_small) end
    # "10000 orders" => fn -> insert_into_exchange.(aux_medium) end,
    # "100000 orders" => fn -> insert_into_exchange.(aux_big) end
  },
  print: %{
    benchmarking: true,
    fast_warning: false,
    configuration: true
  },
  formatters: [
    {Benchee.Formatters.HTML, file: "benchmark/single.html"},
    {Benchee.Formatters.Console, extended_statistics: true}
  ],
  unit_scaling: :smallest,
  memory_time: 5,
  time: 100
)

# Benchee.run(
#   %{
#     "1000*2 orders" => fn -> insert_into_exchange.(mix_small) end,
#     "10000*2 orders" => fn -> insert_into_exchange.(mix_medium) end,
#     "100000*2 orders" => fn -> insert_into_exchange.(mix_big) end
#   },
#   print: %{
#     benchmarking: true,
#     fast_warning: false,
#     configuration: true
#   },
#   formatters: [
#     {Benchee.Formatters.HTML, file: "benchmark/multi.html"},
#     {Benchee.Formatters.Console, extended_statistics: true}
#   ],
#   unit_scaling: :smallest,
#   memory_time: 5,
#   time: 100
# )
