defmodule Exchange.Adapters.MessageBus.OrderPlaced do
  @moduledoc """
  A struct representing the payload of :order_placed events.
  """

  use TypedStruct

  @typedoc "OrderPlaced"
  typedstruct do
    field(:action_indicator, String.t(), enforce: true)
    field(:client_trans_ref, String.t(), enforce: true)
    field(:consideration_currency, String.t(), enforce: true)
    field(:good_until, String.t(), enforce: true)
    field(:last_modified, String.t(), enforce: true)
    field(:limit, integer(), enforce: true)
    field(:order_id, String.t(), enforce: true)
    field(:order_time, String.t(), enforce: true)
    field(:order_value, String.t(), enforce: true)
    field(:quantity, integer(), enforce: true)
    field(:quantity_matched, integer(), enforce: true)
    field(:security_id, String.t(), enforce: true)
    field(:status_code, String.t(), enforce: true)
    field(:total_commission, String.t(), enforce: true)
    field(:total_consideration, String.t(), enforce: true)
    field(:trade_type, String.t(), enforce: true)
    field(:type_code, String.t(), enforce: true)
  end

  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderPlaced.t()
  @doc """
  Decodes the payload to an OrderPlaced struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  def decode_from_jason(data) do
    order = Map.get(data, :order)

    %Exchange.Adapters.MessageBus.OrderPlaced{
      action_indicator: Map.get(order, :action_indicator),
      client_trans_ref: Map.get(order, :client_trans_ref),
      consideration_currency: Map.get(order, :consideration_currency),
      good_until: Map.get(order, :good_until),
      last_modified: Map.get(order, :last_modified),
      limit: Map.get(order, :limit),
      order_id: Map.get(order, :order_id),
      order_time: Map.get(order, :order_time),
      order_value: Map.get(order, :order_value),
      quantity: Map.get(order, :quantity),
      quantity_matched: Map.get(order, :quantity_matched),
      security_id: Map.get(order, :security_id),
      status_code: Map.get(order, :status_code),
      total_commission: Map.get(order, :total_commission),
      total_consideration: Map.get(order, :total_consideration),
      trade_type: Map.get(order, :trade_type),
      type_code: Map.get(order, :type_code)
    }
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.OrderPlaced do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :action_indicator,
        :client_trans_ref,
        :consideration_currency,
        :good_until,
        :last_modified,
        :limit,
        :order_id,
        :order_time,
        :order_value,
        :quantity,
        :quantity_matched,
        :security_id,
        :status_code,
        :total_commission,
        :total_consideration,
        :trade_type,
        :type_code
      ]),
      opts
    )
  end
end
