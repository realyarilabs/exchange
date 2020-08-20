if Code.ensure_loaded?(Instream) do
  defmodule Exchange.Adapters.Flux.Orders do
    @moduledoc """
    InfluxDB support for Orders
    """
    use Instream.Series
    alias Exchange.Adapters.Flux

    series do
      measurement("orders")

      tag(:ticker)
      tag(:side)

      field(:order_id)
      field(:trader_id)
      field(:price)
      field(:size)
      field(:initial_size)
      field(:modified_at)
      field(:type)
    end

    @doc """
    Saves an order from the order book on InfluxDB
    """
    @spec save_order!(order_params :: map) :: any()
    def save_order!(order_params) do
      order_params
      |> convert_into_flux
      |> Flux.Connection.write()
    end

    @spec get_live_orders(ticker :: atom()) :: list()
    def get_live_orders(ticker) do
      response =
        ~s(SELECT * FROM orders WHERE size > 0 AND ticker = '#{ticker}')
        |> Flux.Connection.query(precision: :nanosecond)

      if response.results == [%{statement_id: 0}] do
        []
      else
        Flux.Orders.from_result(response)
      end
    end

    def delete_all_orders! do
      "drop series from orders"
      |> Flux.Connection.query(method: :post)
    end

    defp convert_into_flux(order_params) do
      data = %Flux.Orders{}

      %{
        data
        | fields: %{
            data.fields
            | order_id: order_params.order_id,
              trader_id: order_params.trader_id,
              size: order_params.size,
              initial_size: order_params.initial_size,
              price: order_params.price,
              type: Atom.to_string(order_params.type),
              modified_at: :os.system_time(:nanosecond)
          },
          tags: %{
            data.tags
            | side: Atom.to_string(order_params.side),
              ticker: "AUXLND"
          },
          timestamp: order_params.acknowledged_at
      }
    end
  end
end
