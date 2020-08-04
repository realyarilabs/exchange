defmodule Exchange.MessageBus do
  @moduledoc """
  Behaviour that a message library must implement
  in order to comunicate with the Exchange
  """
  @callback add_listener(key :: String.t()) :: :error|:ok
  @callback remove_listener(key :: String.t()) :: :error|:ok
  @callback cast_event(event :: atom, payload :: any) :: nil | :ok
end
