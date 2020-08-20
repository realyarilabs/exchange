defmodule Exchange.Adapters.TestEventBus do
  @moduledoc """
  Public API to use the adapter of `Exchange.MessageBus`, the Test Event Bus.
  This is used to test the messages sent by the Matching Engine, therefore, it doesn't send any messages it only stores them in memory.
  The `Agent` behaviour is used to encapsulate the messages that are meant to be sent in a real scenario.
  """
  use Agent
  use Exchange.MessageBus, required_config: [], required_deps: []

  def start_link(initial_value \\ Qex.new()) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def append(payload) do
    Agent.update(__MODULE__, &Qex.push(&1, payload))
  end

  def flush do
    Agent.update(__MODULE__, fn _q -> Qex.new() end)
  end

  @events ~w(trade_executed order_queued order_cancelled order_expired price_broadcast)a

  @doc """
  Checks if the `key` is a valid event, if it is valid return `:ok` otherwise returns `:error`

  ## Parameters
    - key: Event to register
  """
  @spec add_listener(any) :: :error | :ok
  def add_listener(key) do
    if Enum.member?(@events, key) do
      :ok
    else
      :error
    end
  end

  @doc """
  Checks if the `key` is a valid event, if it is valid return `:ok` otherwise returns `:error`

  ## Parameters
    - key: Event to unregister
  """
  @spec remove_listener(any) :: :error | :ok
  def remove_listener(key) do
    if Enum.member?(@events, key) do
      :ok
    else
      :error
    end
  end

  @doc """
  Stores the `payload` in the adapter state

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
  def cast_event(:order_cancelled, payload),
    do: dispatch_event(:order_cancelled, payload)

  def cast_event(:trade_executed, payload),
    do: dispatch_event(:trade_executed, payload)

  def cast_event(:order_expired, payload),
    do: dispatch_event(:order_expired, payload)

  def cast_event(:order_queued, payload),
    do: dispatch_event(:order_queued, payload)

  def cast_event(:price_broadcast, payload),
    do: dispatch_event(:price_broadcast, payload)

  defp dispatch_event(key, payload) do
    if Application.get_env(:exchange, :environment) == :test do
      append({:cast_event, key, payload})
    end
  end
end
