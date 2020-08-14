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
end
