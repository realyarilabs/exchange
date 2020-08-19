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

  @doc """
  Decodes the params to an OrderPlaced struct
  ## Parameters
    - params: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderPlaced.t()
  def decode_from_jason(params) do
    %Exchange.Adapters.MessageBus.OrderPlaced{
      action_indicator: Map.get(params, :action_indicator),
      client_trans_ref: Map.get(params, :client_trans_ref),
      consideration_currency: Map.get(params, :consideration_currency),
      good_until: Map.get(params, :good_until),
      last_modified: Map.get(params, :last_modified),
      limit: Map.get(params, :limit),
      order_id: Map.get(params, :order_id),
      order_time: Map.get(params, :order_time),
      order_value: Map.get(params, :order_value),
      quantity: Map.get(params, :quantity),
      quantity_matched: Map.get(params, :quantity_matched),
      security_id: Map.get(params, :security_id),
      status_code: Map.get(params, :status_code),
      total_commission: Map.get(params, :total_commission),
      total_consideration: Map.get(params, :total_consideration),
      trade_type: Map.get(params, :trade_type),
      type_code: Map.get(params, :type_code)
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
