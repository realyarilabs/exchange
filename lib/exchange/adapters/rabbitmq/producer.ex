if Code.ensure_loaded?(AMQP) do
  defmodule Exchange.Adapters.RabbitBus.Producer do
    @moduledoc """
    This module is a server and producer of events.
    It receives requests through the GenServer API and sends messages to an RabbitMQ exchange.
    This module manages the necessary resources to use the RabbitMQ
    """
    use GenServer
    require Logger
    alias AMQP.Connection

    @reconnect_interval 10_000

    def start_link(_) do
      GenServer.start_link(__MODULE__, nil, name: :rabbitmq_producer)
    end

    def init(_) do
      send(self(), :connect)
      {:ok, nil}
    end

    def handle_call({:cast, key, payload}, _, {chan, conn}) do
      message = %Exchange.Adapters.RabbitBus.RabbitMessage{
        event: key,
        payload: Jason.encode!(payload)
      }

      json_message = Jason.encode!(message)
      AMQP.Basic.publish(chan, "event_exchange", "", json_message)
      {:reply, :ok, {chan, conn}}
    end

    def handle_info(:connect, _state) do
      case Connection.open() do
        {:ok, conn} ->
          {:ok, chan} = AMQP.Channel.open(conn)

          # Get notifications when the connection goes down
          Process.monitor(conn.pid)
          {:noreply, {chan, conn}}

        {:error, _} ->
          Logger.error("Failed to connect to RabbitMQ. Reconnecting later...")
          # Retry later
          Process.send_after(self(), :connect, @reconnect_interval)
          {:noreply, nil}
      end
    end

    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
      # Stop GenServer. Will be restarted by Supervisor.
      {:stop, {:connection_lost, reason}, nil}
    end
  end
end
