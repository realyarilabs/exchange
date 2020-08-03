defmodule EventBus.PriceBroadcast do
  @moduledoc """
  A struct representing the payload of :order_queued events.
  """

  use TypedStruct

  @typedoc "OrderQueued"
  typedstruct do
    field(:ticker, atom(), enforce: true)
    field(:ask_min, integer(), enforce: true)
    field(:bid_max, integer(), enforce: true)
  end
end
