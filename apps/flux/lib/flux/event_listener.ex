defmodule Flux.EventListener do
  @moduledoc """
  Server that listens for Subscribed Events from EventBus
  and Dispatches Actions for Flux App
  """
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state) do
    EventBus.add_listener(:trade_executed)
    EventBus.add_listener(:order_queued)
    EventBus.add_listener(:order_cancelled)
    EventBus.add_listener(:order_expired)

    {:ok, state}
  end

  def handle_info({:cast_event, :trade_executed, %EventBus.TradeExecuted{} = payload}, state) do
    Flux.Trades.process_trade!(payload)
    Logger.info("[Flux] Processing trade: #{inspect(payload)}")
    {:noreply, state}
  end

  def handle_info({:cast_event, :order_queued, %EventBus.OrderQueued{order: order}}, state) do
    Logger.info("[F] Processing Order: #{inspect(order)}")
    Flux.Orders.save_order!(order)
    {:noreply, state}
  end

  def handle_info({:cast_event, :order_cancelled, %EventBus.OrderCancelled{order: order}}, state) do
    Logger.info("[F] Processing Order: #{inspect(order)}")

    %{order | size: 0}
    |> Flux.Orders.save_order!()

    {:noreply, state}
  end

  def handle_info({:cast_event, :order_expired, %EventBus.OrderExpired{order: order}}, state) do
    Logger.info("[F] Processing Order: #{inspect(order)}")

    %{order | size: 0}
    |> Flux.Orders.save_order!()

    {:noreply, state}
  end

end
