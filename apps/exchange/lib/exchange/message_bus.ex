defmodule Exchange.MessageBus do

  @callback add_listener(key :: String.t()) :: :error|:ok
  @callback remove_listener(key :: String.t()) :: :error|:ok
  @callback cast_event(event :: atom, payload :: any) :: nil | :ok
end
