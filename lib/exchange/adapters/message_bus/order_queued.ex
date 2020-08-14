defmodule Exchange.Adapters.MessageBus.OrderQueued do
  @moduledoc """
  A struct representing the payload of :order_queued events.
  """

  use TypedStruct

  @typedoc "OrderQueued"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end
end
