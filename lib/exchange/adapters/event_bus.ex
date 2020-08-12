defmodule Exchange.Adapters.EventBus do
  @moduledoc """
  Public API to use the adapter of `Exchange.MessageBus`, the Event Bus.
  This module uses the Registry to un/register processes under a event and send messages to the registered processes.
  """
  alias Exchange.Adapters.EventBus

  use Exchange.Adapter
  @behaviour Exchange.MessageBus
  @events ~w(trade_executed order_queued order_cancelled order_expired
             transaction_open order_placed trade_processed price_broadcast)a

  @doc """
  Adds the process calling this function to the `Registry` under the given `key`

  ## Parameters
    - key: Event to register the process
  """
  @spec add_listener(any) :: :error | :ok
  def add_listener(key) do
    if Enum.member?(@events, key) do
      {:ok, _} = Registry.register(Exchange.Adapters.EventBus.Registry, key, [])
      :ok
    else
      :error
    end
  end

  @doc """
  Removes the process calling this function to the `Registry`

  ## Parameters
    - key: Event to register the process
  """
  @spec remove_listener(any) :: :error | :ok
  def remove_listener(key) do
    if Enum.member?(@events, key) do
      Registry.unregister(Exchange.Adapters.EventBus.Registry, key)
    else
      :error
    end
  end

  @doc """
  Sends a message to all registered processes under the permitted events.
  The `payload` is sent through the `Registry` module using `dispatch/3`

  ## Parameters
    - key: Payload's event type
    - payload: Data to be sent to the processes
  """
  @spec cast_event(
          :order_cancelled
          | :order_expired
          | :order_placed
          | :order_queued
          | :price_broadcast
          | :trade_executed
          | :trade_processed,
          any
        ) :: nil | :ok
  def cast_event(:order_cancelled, payload),
    do: dispatch_event(:order_cancelled, %EventBus.OrderCancelled{order: payload})

  def cast_event(:trade_executed, payload),
    do: dispatch_event(:trade_executed, %EventBus.TradeExecuted{trade: payload})

  def cast_event(:order_expired, payload),
    do: dispatch_event(:order_expired, %EventBus.OrderExpired{order: payload})

  def cast_event(:order_placed, payload),
    do: dispatch_event(:order_placed, %EventBus.OrderPlaced{} = payload)

  def cast_event(:order_queued, payload),
    do: dispatch_event(:order_queued, %EventBus.OrderQueued{order: payload})

  def cast_event(:trade_processed, payload),
    do: dispatch_event(:trade_processed, %EventBus.TradeProcessed{} = payload)

  def cast_event(:price_broadcast, payload) do
    price_broadcast_event = %EventBus.PriceBroadcast{
      ticker: payload.ticker,
      ask_min: payload.ask_min,
      bid_max: payload.bid_max
    }

    dispatch_event(:price_broadcast, price_broadcast_event)
  end

  defp dispatch_event(key, payload) do
    if Application.get_env(:event_bus, :environment) != :test do
      Registry.dispatch(Exchange.Adapters.EventBus.Registry, key, fn entries ->
        for {pid, _} <- entries, do: send(pid, {:cast_event, key, payload})
      end)
    end
  end
end
