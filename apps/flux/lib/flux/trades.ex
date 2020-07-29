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

  def completed_trades_by_id(ticker, trader_id) do
    response =
      ~s(SELECT * FROM trades WHERE buyer_id = '#{trader_id}' or seller_id = '#{trader_id}' and ticker = '#{ticker}')
      |> Flux.Connection.query(precision: :nanosecond)

    if response.results == [%{statement_id: 0}] do
      []
    else
      Flux.Trades.from_result(response)
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
