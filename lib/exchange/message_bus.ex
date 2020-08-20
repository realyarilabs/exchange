defmodule Exchange.MessageBus do
  @moduledoc """
  Behaviour that a message library adapter must implement
  in order to communicate with the Exchange
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_config opts[:required_config] || []
      @required_deps opts[:required_deps] || []
      @behaviour Exchange.MessageBus
      alias Exchange.Adapters.Helpers

      def validate_config(config \\ []) do
        Helpers.validate_config(@required_config, config, __MODULE__)
      end

      @on_load :validate_dependency
      def validate_dependency do
        Helpers.validate_dependency(@required_deps, __MODULE__)
      end
    end
  end

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
