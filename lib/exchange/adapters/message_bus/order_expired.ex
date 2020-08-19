defmodule Exchange.Adapters.MessageBus.OrderExpired do
  @moduledoc """
  A struct representing the payload of :order_expired events.
  """

  use TypedStruct

  @typedoc "OrderExpired"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end

  @doc """
  Decodes the params to an OrderExpired struct
  ## Parameters
    - params: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderExpired.t()
  def decode_from_jason(params) do
    order = Map.get(params, :order)
    %Exchange.Adapters.MessageBus.OrderExpired{order: Exchange.Order.decode_from_jason(order)}
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.OrderExpired do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order
      ]),
      opts
    )
  end
end
