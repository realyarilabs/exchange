defmodule Exchange.Adapter do
  @moduledoc ~S"""
  Specification of the email delivery adapter.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @required_deps opts[:required_deps] || []
      @behaviour Exchange.Adapter

      def validate_dependency do
        Exchange.Adapter.validate_dependency(@required_deps)
      end
    end
  end

  @callback validate_dependency() :: :ok | [module | {atom, module}]

  @spec validate_dependency([module | {atom, module}]) :: :ok | no_return
  def validate_dependency(required_deps) do
    missing_dependencies =
      Enum.reduce(
        required_deps,
        [],
        fn dep, acc_missing_dependencies ->
          dep_loaded =
            case dep do
              {_lib, module} ->
                Code.ensure_loaded?(module)

              module ->
                Code.ensure_loaded?(module)
            end

          if !dep_loaded do
            [dep | acc_missing_dependencies]
          else
            acc_missing_dependencies
          end
        end
      )

    raise_on_missing_dependency(missing_dependencies)
  end

  defp raise_on_missing_dependency([]), do: :ok

  defp raise_on_missing_dependency(keys) do
    raise ArgumentError, """
    expected module(s) #{inspect(keys)} to be loaded.
    Run mix deps.get.
    """
  end
end
