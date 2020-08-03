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
    message_bus().add_listener(:trade_executed)
    message_bus().add_listener(:order_queued)
    message_bus().add_listener(:order_cancelled)
    message_bus().add_listener(:order_expired)
    message_bus().add_listener(:price_broadcast)

    {:ok, state}
  end

  def handle_info({:cast_event, :trade_executed, payload}, state) do
    Flux.Trades.process_trade!(payload.trade)
    Logger.info("[Flux] Processing trade: #{inspect(payload.trade)}")
    {:noreply, state}
  end

  def handle_info({:cast_event, :order_queued, queued_order}, state) do
    Logger.info("[F] Processing Order: #{inspect(queued_order.order)}")
    Flux.Orders.save_order!(queued_order.order)
    {:noreply, state}
  end

  def handle_info({:cast_event, :order_cancelled, order_cancelled}, state) do
    Logger.info("[F] Processing Order: #{inspect(order_cancelled.order)}")
    order = order_cancelled.order
    %{order | size: 0}
    |> Flux.Orders.save_order!()

    {:noreply, state}
  end

  def handle_info({:cast_event, :order_expired, expired_order}, state) do
    Logger.info("[F] Processing Order: #{inspect(expired_order.order)}")
    order = expired_order.order
    %{order | size: 0}
    |> Flux.Orders.save_order!()

    {:noreply, state}
  end

  def handle_info({:cast_event, :price_broadcast, price}, state) do
    Logger.info("[F] Processing Price: #{inspect(price)}")
    IO.puts("PBF")
    %{ticker: price.ticker, ask_min: price.ask_min, bid_max: price.bid_max}
    |> Flux.Prices.save_price!()

    {:noreply, state}
  end

  defp message_bus do
    Application.get_env(:flux, Flux.EventListener)[:message_bus_adapter]

  end

end
