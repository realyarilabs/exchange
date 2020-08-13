defmodule Exchange.Validations do
  @moduledoc """
  Validations for Data Structures for the Exchange
  """

  @doc """
  Function that validates the parameters of an order taking into account the type of the `Exchange.Order`.


  Different validations are made:
  - price is positive
  - side one of [:buy, :sell]
  - size is positive
  - exp_time is a date in future

  ## Parameters

    - order_params: Map that represents the parameters on an `Exchange.Order`.
  """
  @spec cast_order(%{type: :limit | :market | :marketable_limit}) ::
          {:ok, Exchange.Order.order()} | {:error, String.t()}
  def cast_order(%{type: :limit} = order_params) do
    validate(order_params)
  end

  def cast_order(%{type: type} = order_params)
      when type == :market or type == :marketable_limit do
    order_params
    |> Map.put(:price, 0)
    |> validate
  end

  defp validate(%{price: p, side: s, size: z} = order_params) do
    with {:ok, price} <- validate(:price, p),
         {:ok, side} <- validate(:side, s),
         {:ok, size} <- validate(:positive_num, z),
         {:ok, time} <- validate(:exp_time, order_params[:exp_time]) do
      {:ok,
       %Exchange.Order{
         order_id: order_params[:order_id],
         trader_id: order_params[:trader_id],
         side: side,
         size: size,
         initial_size: size,
         price: price,
         type: order_params[:type],
         exp_time: time,
         ticker: order_params[:ticker]
       }}
    else
      err -> err
    end
  end

  defp validate(:price, %Money{} = price) do
    if Money.positive?(price) and price.currency == :GBP do
      {:ok, price.amount}
    else
      {:error, "Price must be a positive amount in GBP"}
    end
  end

  defp validate(:price, price) when is_number(price) and price >= 0 do
    {:ok, price}
  end

  defp validate(:price, _price), do: {:error, "price must be a positive number"}

  defp validate(:side, side) do
    if Enum.member?([:buy, :sell], side) do
      {:ok, side}
    else
      {:error, "Order Side accepted values are: - :buy or :sell"}
    end
  end

  defp validate(:positive_num, num) when is_number(num) and num > 0 do
    {:ok, num}
  end

  defp validate(:positive_num, _num), do: {:error, "size must be a positive number"}

  defp validate(:exp_time, %DateTime{} = time) do
    now = DateTime.utc_now()

    case DateTime.compare(time, now) do
      :gt -> {:ok, DateTime.to_unix(time, :millisecond)}
      _ -> {:error, "exp_time must be a DateTime in the future"}
    end
  end

  defp validate(:exp_time, nil), do: {:ok, nil}

  defp validate(:exp_time, _), do: {:error, "exp_time must be a valid DateTime"}
end
