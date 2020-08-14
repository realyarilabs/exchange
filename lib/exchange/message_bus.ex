defmodule Exchange.MessageBus do
  @moduledoc """
  Behaviour that a message library adapter must implement
  in order to communicate with the Exchange
  """
  @doc """
  The current process subscribes to event of type key

  ## Parameters
    - key: Atom that represents an event
  """
  @callback add_listener(key :: String.t()) :: :error | :ok
  @doc """
  The current process unsubscribes to event of type key

  ## Parameters
    - key: Atom that represents an event
  """
  @callback remove_listener(key :: String.t()) :: :error | :ok
  @doc """
  Sends a message with a topic of event and content of payload

  ## Parameters
    - event: Atom that represents a topic
    - payload: Data to send to subscribers
  """
  @callback cast_event(event :: atom, payload :: any) :: nil | :ok
end
