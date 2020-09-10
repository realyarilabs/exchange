defmodule Exchange.Adapters.EventBus do
  @moduledoc """
  Public API to use the adapter of `Exchange.MessageBus`, the Event Bus.
  This module uses the Registry to un/register processes under a event and send messages to the registered processes.
  """
  alias Exchange.Adapters.MessageBus

  use Exchange.MessageBus, required_config: [], required_deps: []
  @events ~w(trade_executed order_queued order_cancelled order_expired price_broadcast)a

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
          | :order_queued
          | :price_broadcast
          | :trade_executed,
          any
        ) :: nil | :ok
  def cast_event(:order_cancelled, %MessageBus.OrderCancelled{} = payload),
    do: dispatch_event(:order_cancelled, payload)

  def cast_event(:trade_executed, %MessageBus.TradeExecuted{} = payload),
    do: dispatch_event(:trade_executed, payload)

  def cast_event(:order_expired, %MessageBus.OrderExpired{} = payload),
    do: dispatch_event(:order_expired, payload)

  def cast_event(:order_queued, %MessageBus.OrderQueued{} = payload),
    do: dispatch_event(:order_queued, payload)

  def cast_event(:price_broadcast, %MessageBus.PriceBroadcast{} = payload),
    do: dispatch_event(:price_broadcast, payload)

  defp dispatch_event(key, payload) do
    if Application.get_env(:event_bus, :environment) != :test do
      Registry.dispatch(Exchange.Adapters.EventBus.Registry, key, fn entries ->
        for {pid, _} <- entries, do: send(pid, {:cast_event, key, payload})
      end)
    end
  end
end
