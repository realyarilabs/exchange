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

  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.PriceBroadcast.t()
  @doc """
  Decodes the payload to a PriceBroadcast struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  def decode_from_jason(price) do
    %Exchange.Adapters.MessageBus.PriceBroadcast{
      ticker:
        Map.get(price, :ticker)
        |> String.to_atom(),
      ask_min: Map.get(price, :ask_min),
      bid_max: Map.get(price, :bid_max)
    }
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.PriceBroadcast do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :ticker,
        :ask_min,
        :bid_max
      ]),
      opts
    )
  end
end
