defmodule Exchange.TimeSeries do
  @moduledoc """
  Behaviour that a time series database must implement
  to be able to communicate with the Exchange.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_config opts[:required_config] || []
      @required_deps opts[:required_deps] || []
      @behaviour Exchange.TimeSeries
      alias Exchange.Adapters.Helpers

      def validate_config(config) do
        Helpers.validate_config(@required_config, config)
      end

      @on_load :validate_dependency
      def validate_dependency do
        Helpers.validate_dependency(@required_deps)
      end
    end
  end

  @doc """
  Function that fetches the completed trades from a market which a specific user participated.
  """
  @callback completed_trades_by_id(atom, String.t()) :: [Exchange.Trade]
  @doc """
  Function that fetches the active orders of the application.
  It is called when the application starts running allowing the recovery of the previous state when a crash happens.
  """
  @callback get_live_orders(atom) :: [Exchange.Order]
end
