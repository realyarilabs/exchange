defmodule Exchange.Adapters.MessageBus.PriceBroadcast do
  @moduledoc """
  A struct representing the payload of :price_broadcast events.
  """

  use TypedStruct

  @typedoc "PriceBroadcast"
  typedstruct do
    field(:ticker, atom(), enforce: true)
    field(:ask_min, integer(), enforce: true)
    field(:bid_max, integer(), enforce: true)
  end
end
