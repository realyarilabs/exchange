defmodule Flux.Trades do
  @moduledoc """
  InfluxDB support for Trades
  """
  use Instream.Series

  series do
    measurement("trades")

    tag(:ticker, default: "AUXLND")
    tag(:currency, default: "GBP")
    tag(:buyer_id)
    tag(:seller_id)

    field(:type)
    field(:trade_id)
    field(:buy_order_id)
    field(:sell_order_id)
    field(:buy_init_size)
    field(:sell_init_size)
    field(:price)
    field(:size)
    field(:acknowledged_at)
  end

  def process_trade!(%EventBus.TradeExecuted{} = trade_params) do
    data = %Flux.Trades{}
    t = trade_params.trade

    %{
      data
      | fields: %{
          data.fields
          | trade_id: t.trade_id,
            buy_order_id: t.buy_order_id,
            sell_order_id: t.sell_order_id,
            size: t.size,
            buy_init_size: t.buy_init_size,
            sell_init_size: t.sell_init_size,
            price: t.price,
            acknowledged_at: t.acknowledged_at,
            type: Atom.to_string(t.type)
        },
        tags: %{data.tags | seller_id: t.seller_id, buyer_id: t.buyer_id}
    }
    |> Flux.Connection.write()
  end
end
