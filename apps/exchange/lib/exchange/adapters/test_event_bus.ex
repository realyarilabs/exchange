defmodule Exchange.Adapters.TestEventBus do
  use Agent

  def start_link(initial_value \\ Qex.new()) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def append(payload) do
    Agent.update(__MODULE__, &(Qex.push(&1, payload)))
  end

  def flush do
    Agent.update(__MODULE__, fn _q -> Qex.new() end)
  end

  @behaviour Exchange.MessageBus
  @events ~w(trade_executed order_queued order_cancelled order_expired
             transaction_open order_placed trade_processed price_broadcast)a

  def add_listener(key) do
    if Enum.member?(@events, key) do
      :ok
    else
      :error
    end
  end

  def remove_listener(key) do
    if Enum.member?(@events, key) do
      :ok
    else
      :error
    end
  end

  def cast_event(:order_cancelled, payload),
    do: dispatch_event(:order_cancelled, payload)

  def cast_event(:trade_executed, payload),
    do: dispatch_event(:trade_executed,  payload)

  def cast_event(:order_expired, payload)
    do
      IO.puts("Exppired")
      dispatch_event(:order_expired, payload)
    end

  def cast_event(:order_placed, payload),
    do: dispatch_event(:order_placed,  payload)

  def cast_event(:order_queued, payload),
    do: dispatch_event(:order_queued,  payload)

  def cast_event(:trade_processed, payload),
    do: dispatch_event(:trade_processed,  payload)

  def cast_event(:price_broadcast, payload),
    do: dispatch_event(:price_broadcast, payload)

  defp dispatch_event(key, payload) do
    if System.get_env("MIX_ENV") == "test" do
      append({:cast_event, key, payload})
    end
  end
end
