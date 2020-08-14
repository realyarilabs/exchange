defmodule Exchange.Adapters.MessageBus.OrderCancelled do
  @moduledoc """
  A struct representing the payload of :order_cancelled events.
  """

  use TypedStruct

  @typedoc "OrderCancelled"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end
end
