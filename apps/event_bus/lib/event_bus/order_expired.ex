defmodule EventBus.OrderExpired do
  @moduledoc """
  A struct representing the payload of :order_expired events.
  """

  use TypedStruct

  @typedoc "OrderExpired"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end
end
