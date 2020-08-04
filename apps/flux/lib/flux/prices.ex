defmodule Flux.Prices do
  @moduledoc """
  InfluxDB support for Prices
  """

  use Instream.Series

  series do
    measurement("prices")
    tag(:ticker)

    field(:ask_min)
    field(:bid_max)
  end

  @doc """
  Saves an order from the order book on InfluxDB
  """
  def save_price!(price_params) do
    price_params
    |> convert_into_flux
    |> Flux.Connection.write()
  end

  def delete_all_prices! do
    "drop series from prices"
    |> Flux.Connection.query(method: :post)
  end

  defp convert_into_flux(price_params) do
    data = %Flux.Prices{}

    %{
      data
      | fields: %{
          data.fields
          | ask_min: price_params.ask_min,
            bid_max: price_params.bid_max,
        },
        tags: %{
          data.tags
          | ticker: price_params.ticker
        },
    }
  end
end
