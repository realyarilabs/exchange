defmodule EventBus.OrderPlaced do
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
end
