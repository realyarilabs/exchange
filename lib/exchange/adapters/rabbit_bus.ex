defmodule Exchange.Adapters.RabbitBus do
  @moduledoc """
  Public API to use the adapter of `Exchange.MessageBus`, the RabbitBus.
  To use this adapter is necessary to add the AMQP to the dependencies.
  """
  use Exchange.MessageBus, required_config: [], required_deps: [amqp: AMQP]
  alias AMQP.{Connection, Queue}

  alias Exchange.Adapters.MessageBus
  @exchange "event_exchange"
  @queue "event_queue"
  @queue_error "#{@queue}_error"
  @events ~w(trade_executed order_queued order_cancelled order_expired price_broadcast)a

  def init do
    setup_resources()

    {:ok,
     [
       Exchange.Adapters.RabbitBus.Consumer,
       Exchange.Adapters.RabbitBus.Producer
     ]}
  end

  @doc """
  It calls the consumer server and it adds the process calling to the subscribers of the event.

  ## Parameters
    - key: Event to register the process
  """
  @spec add_listener(key :: String.t()) :: :error | :ok
  def add_listener(key) do
    if Enum.member?(@events, key) do
      GenServer.call(:rabbitmq_consumer, {:add_listener, key, self()})
    else
      :error
    end
  end

  @doc """
  It calls the consumer server and it removes the process calling from the subscribers of the event.

  ## Parameters
    - key: Event to register the process
  """
  @spec remove_listener(key :: String.t()) :: :error | :ok
  def remove_listener(key) do
    if Enum.member?(@events, key) do
      GenServer.call(:rabbitmq_consumer, {:remove_listener, key, self()})
    else
      :error
    end
  end

  @doc """
  It calls the producer server and sends it the event and the payload to be casted.

  ## Parameters
    - key: Event to register the process
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
    do: dispatch_event(:order_cancelled, %MessageBus.OrderCancelled{order: payload})

  def cast_event(:trade_executed, payload),
    do: dispatch_event(:trade_executed, %MessageBus.TradeExecuted{trade: payload})

  def cast_event(:order_expired, payload),
    do: dispatch_event(:order_expired, %MessageBus.OrderExpired{order: payload})

  def cast_event(:order_queued, payload),
    do: dispatch_event(:order_queued, %MessageBus.OrderQueued{order: payload})

  def cast_event(:price_broadcast, payload) do
    price_broadcast_event = %MessageBus.PriceBroadcast{
      ticker: payload.ticker,
      ask_min: payload.ask_min,
      bid_max: payload.bid_max
    }

    dispatch_event(:price_broadcast, price_broadcast_event)
  end

  defp dispatch_event(key, payload) do
    if Application.get_env(:event_bus, :environment, :prod) != :test do
      GenServer.call(:rabbitmq_producer, {:cast, key, payload})
    end
  end

  @doc """
  Creates the necessary exchange and queue to this adapter and binds them.
  """
  @spec setup_resources() :: :ok
  def setup_resources do
    require Logger

    case Connection.open() do
      {:ok, conn} ->
        {:ok, chan} = AMQP.Channel.open(conn)

        {:ok, _} = Queue.declare(chan, @queue_error, durable: true)

        # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
        {:ok, _} =
          Queue.declare(chan, @queue,
            durable: true,
            arguments: [
              {"x-dead-letter-exchange", :longstr, ""},
              {"x-dead-letter-routing-key", :longstr, @queue_error}
            ]
          )

        :ok = AMQP.Exchange.direct(chan, @exchange, durable: true)
        :ok = Queue.bind(chan, @queue, @exchange)
        Connection.close(conn)

      {:error, _} ->
        Logger.error("Failed to connect to RabbitMQ. Reconnecting later...")
        # Retry later
        Process.sleep(3000)
        setup_resources()
    end
  end
end
