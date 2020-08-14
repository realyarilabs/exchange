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
