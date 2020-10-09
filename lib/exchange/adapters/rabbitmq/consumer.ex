if Code.ensure_loaded?(AMQP) do
  defmodule Exchange.Adapters.RabbitBus.Consumer do
    @moduledoc """
    This module is a server and consumer of events.
    This server handles the addition and removal of listener processes.
    It consumes messages from a RabbitMQ queue, decodes the message and then the message is broadcasted to every listener.
    This module manages the necessary resources to use the RabbitMQ
    """
    use GenServer
    require Logger
    alias AMQP.{Basic, Connection}

    @reconnect_interval 10_000

    def start_link(_) do
      GenServer.start_link(__MODULE__, %{chan: nil, subs: %{}}, name: :rabbitmq_consumer)
    end

    def init(state) do
      send(self(), :connect)
      {:ok, state}
    end

    # Removes a subscriber of event
    def handle_call({:remove_listener, event, subscriber}, _, %{chan: _, subs: subs} = state) do
      event_subs =
        Map.get(subs, event, [])
        |> List.delete(subscriber)

      # subs = Map.put(subs, event, event_subs)
      state = put_in(state[:subs][event], event_subs)
      {:reply, :ok, state}
    end


    # Adds a subscriber of event
    def handle_call({:add_listener, event, subscriber}, _, %{chan: _, subs: subs} = state) do
      event_subs = Map.get(subs, event, [])

      state =
        if !Enum.member?(event_subs, subscriber) do
          event_subs = [subscriber | event_subs]
          put_in(state[:subs][event], event_subs)
          # subs = Map.put(subs, event, event_subs)
          # Map.put(state, :subs, subs)
        end

      {:reply, :ok, state}
    end

    defp consume(channel, tag, redelivered, message, subs) do
      message = Jason.decode!(message, keys: :atoms)

      event =
        Map.get(message, :event)
        |> String.to_atom()

      event_type =
        case event do
          :trade_executed ->
            Exchange.Adapters.MessageBus.TradeExecuted

          :order_queued ->
            Exchange.Adapters.MessageBus.OrderQueued

          :order_cancelled ->
            Exchange.Adapters.MessageBus.OrderCancelled

          :order_expired ->
            Exchange.Adapters.MessageBus.OrderExpired

          :price_broadcast ->
            Exchange.Adapters.MessageBus.PriceBroadcast

          _ ->
            :ok = Basic.reject(channel, tag, requeue: false)
            Logger.warn("Unknown event: #{event}")
        end

      json_payload = Map.get(message, :payload)
      payload = Jason.decode!(json_payload, keys: :atoms)
      data = event_type.decode_from_jason(payload)

      subs
      |> Map.get(event, [])
      |> Enum.each(fn pid ->
        send(pid, {:cast_event, event, data})
      end)

      :ok = Basic.ack(channel, tag)
    rescue
      exception ->
        :ok = Basic.reject(channel, tag, requeue: not redelivered)
        Logger.warn("Error converting payload: #{inspect(exception)}")
    end

    def handle_info(
          {:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered} = _other},
          %{chan: chan, subs: subs} = state
        ) do
      # You might want to run payload consumption in separate Tasks in production
      consume(chan, tag, redelivered, payload, subs)
      {:noreply, state}
    end

    # Default handles
    #################################################################################
    def handle_info(:connect, state) do
      case Connection.open() do
        {:ok, conn} ->
          {:ok, chan} = AMQP.Channel.open(conn)
          # Limit unacknowledged messages to 10
          :ok = Basic.qos(chan, prefetch_count: 10)
          # Register the GenServer process as a consumer
          {:ok, _consumer_tag} = Basic.consume(chan, "event_queue")
          # Get notifications when the connection goes down
          Process.monitor(conn.pid)
          state = Map.put(state, :chan, chan)
          {:noreply, state}

        {:error, _} ->
          Logger.error("Failed to connect to RabbitMQ. Reconnecting later...")
          # Retry later
          Process.send_after(self(), :connect, @reconnect_interval)
          {:noreply, nil}
      end
    end

    # Confirmation sent by the broker after registering this process as a consumer
    def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
      {:noreply, state}
    end

    # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
    def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
      {:stop, :normal, state}
    end

    # Confirmation sent by the broker to the consumer process after a Basic.cancel
    def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
      {:noreply, state}
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
      # Stop GenServer. Will be restarted by Supervisor.
      {:stop, {:connection_lost, reason}, nil}
    end

    #################################################################################
  end
end
