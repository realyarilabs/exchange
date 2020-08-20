defmodule Exchange.Adapters.MessageBus.OrderQueued do
  @moduledoc """
  A struct representing the payload of :order_queued events.
  """

  use TypedStruct

  @typedoc "OrderQueued"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end

  @doc """
  Decodes the params to an OrderQueued struct
  ## Parameters
    - params: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderQueued.t()
  def decode_from_jason(params) do
    order = Map.get(params, :order)
    order = Exchange.Order.decode_from_jason(order)
    %Exchange.Adapters.MessageBus.OrderQueued{order: order}
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.OrderQueued do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order
      ]),
      opts
    )
  end
end
