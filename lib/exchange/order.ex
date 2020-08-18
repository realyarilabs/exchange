defmodule Exchange.Order do
  @moduledoc """
  A struct representing an Order to be placed in the Exchange

  side: :buy, :sell
  type: :market, :limit

  trader_id: Alchemist or the user_id
  expiration_time: unix timestamp in milliseconds when the order expires
  """
  defstruct order_id: nil,
            trader_id: nil,
            side: :buy,
            price: 0,
            size: 0,
            initial_size: 0,
            type: :market,
            exp_time: nil,
            acknowledged_at: :os.system_time(:nanosecond),
            modified_at: :os.system_time(:nanosecond),
            ticker: nil

  @type price_in_cents :: integer
  @type size_in_grams :: integer

  @type order :: %Exchange.Order{
          order_id: String.t(),
          trader_id: String.t(),
          side: atom,
          price: price_in_cents,
          size: size_in_grams,
          initial_size: size_in_grams,
          type: atom,
          ticker: atom,
          exp_time: integer | atom
        }

  @doc """
  Decodes the payload to an Order struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Order.order()
  def decode_from_jason(order) do
    %Exchange.Order{
      order_id: Map.get(order, :order_id),
      trader_id: Map.get(order, :trader_id),
      side: String.to_atom(Map.get(order, :side)),
      price: Map.get(order, :price),
      size: Map.get(order, :size),
      initial_size: Map.get(order, :initial_size),
      type: String.to_atom(Map.get(order, :type)),
      exp_time: Map.get(order, :exp_time),
      acknowledged_at: Map.get(order, :acknowledged_at),
      modified_at: Map.get(order, :modified_at),
      ticker: Map.get(order, :ticker) |> String.to_atom()
    }
  end
end

defimpl Jason.Encoder, for: Exchange.Order do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order_id,
        :trader_id,
        :side,
        :price,
        :size,
        :initial_size,
        :type,
        :exp_time,
        :acknowledged_at,
        :modified_at,
        :ticker
      ]),
      opts
    )
  end
end
