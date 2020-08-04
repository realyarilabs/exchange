defmodule Exchange.Adapters.EventBus do
  @moduledoc """
  Documentation for an EventBus adapter
  """
  @behaviour Exchange.MessageBus

  def add_listener(key) do
    EventBus.add_listener(key)
  end

  def remove_listener(key) do
    EventBus.remove_listener(key)
  end

  def cast_event(:order_cancelled, payload),
    do: EventBus.cast_event(:order_cancelled, payload)

  def cast_event(:trade_executed, payload),
    do: EventBus.cast_event(:trade_executed, payload)

  def cast_event(:order_expired, payload),
    do: EventBus.cast_event(:order_expired, payload)

  def cast_event(:order_placed, payload),
    do: EventBus.cast_event(:order_placed, payload)

  def cast_event(:order_queued, payload),
    do: EventBus.cast_event(:order_queued, payload)

  def cast_event(:trade_processed, payload),
    do: EventBus.cast_event(:trade_processed, payload)

  def cast_event(:price_broadcast, payload),
    do: EventBus.cast_event(:price_broadcast, payload)
end
