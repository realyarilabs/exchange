defmodule Exchange.Adapters.MessageBus.TradeProcessed do
  @moduledoc """
  A struct representing the payload of :trade_processed events.
  """

  use TypedStruct

  @typedoc "TradeProcessed"
  typedstruct do
    field(:trade_id, Ecto.UUID.t(), enforce: true)
    field(:ticker, atom(), enforce: true)
    field(:currency, atom(), enforce: true)
    field(:buyer_id, Ecto.UUID.t(), enforce: true)
    field(:seller_id, Ecto.UUID.t(), enforce: true)
    field(:buy_order_id, Ecto.UUID.t(), enforce: true)
    field(:sell_order_id, Ecto.UUID.t(), enforce: true)
    field(:price, Money.t(), enforce: true)
    field(:size, integer(), enforce: true)
    field(:acknowledged_at, integer(), enforce: true)
    field(:buy_commission, Money.t(), enforce: true)
    field(:sell_commission, Money.t(), enforce: true)
    field(:buy_total, Money.t(), enforce: true)
    field(:sell_total, Money.t(), enforce: true)
  end

  def decode_from_jason(data) do
    data
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.TradeProcessed do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :trade_id,
        :ticker,
        :currency,
        :buyer_id,
        :seller_id,
        :buy_order_id,
        :sell_order_id,
        :price,
        :size,
        :acknowledged_at,
        :buy_commission,
        :sell_commission,
        :buy_total,
        :sell_total
      ]),
      opts
    )
  end
end
