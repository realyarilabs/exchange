defmodule Exchange.Adapters.RabbitBus do
  @moduledoc """
  Public API to use the adapter of `Exchange.MessageBus`, the RabbitMQ Bus.
  """
  alias Exchange.Adapters.MessageBus
  use Exchange.MessageBus, required_config: [], required_deps: [:amqp]
  @events ~w(trade_executed order_queued order_cancelled order_expired
             transaction_open order_placed trade_processed price_broadcast)a

  @spec add_listener(key :: String.t()) :: :error | :ok
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
  @spec remove_listener(key :: String.t()) :: :error | :ok
  def remove_listener(key) do
    if Enum.member?(@events, key) do
      Registry.unregister(Exchange.Adapters.EventBus.Registry, key)
    else
      :error
    end
  end

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
    do: dispatch_event(:order_cancelled, %MessageBus.OrderCancelled{order: payload})

  def cast_event(:trade_executed, payload),
    do: dispatch_event(:trade_executed, %MessageBus.TradeExecuted{trade: payload})

  def cast_event(:order_expired, payload),
    do: dispatch_event(:order_expired, %MessageBus.OrderExpired{order: payload})

  def cast_event(:order_placed, payload),
    do: dispatch_event(:order_placed, %MessageBus.OrderPlaced{} = payload)

  def cast_event(:order_queued, payload),
    do: dispatch_event(:order_queued, %MessageBus.OrderQueued{order: payload})

  def cast_event(:trade_processed, payload),
    do: dispatch_event(:trade_processed, %MessageBus.TradeProcessed{} = payload)

  def cast_event(:price_broadcast, payload) do
    price_broadcast_event = %MessageBus.PriceBroadcast{
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
