if Code.ensure_loaded?(Instream.Connection) do
  defmodule Exchange.Adapters.Flux do
    @moduledoc """
    Public API to use the adapter of `Exchange.TimeSeries`, the Flux.
    This module uses the InfluxDB to write and query the data
    To use this adapter is necessary to add the Instream.Connection to the dependencies.
          config :exchange, Exchange.Adapters.Flux.Connection,
            database: System.get_env("FLUX_DB_NAME") || "dbname",
            host: System.get_env("FLUX_DB_HOST") || "localhost",
            port: System.get_env("FLUX_DB_PORT") || 8086`
    """
    use Exchange.TimeSeries,
      required_config: [:database, :host, :port],
      required_deps: [Instream.Connection]

    alias Exchange.Adapters.Flux.{Orders, Trades}

    def completed_trades(ticker) do
      Trades.completed_trades(ticker)
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

    def completed_trades_by_id(ticker, trader_id) do
      Trades.completed_trades_by_id(ticker, trader_id)
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

    def get_live_orders(ticker) do
      Orders.get_live_orders(ticker)
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

    @spec get_completed_trade_by_trade_id(ticker :: atom, trade_id :: String.t()) ::
            Exchange.Trade
    def get_completed_trade_by_trade_id(ticker, trade_id) do
      Trades.get_completed_trade_by_trade_id(ticker, trade_id)
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
      |> List.first()
    end
  end
end
