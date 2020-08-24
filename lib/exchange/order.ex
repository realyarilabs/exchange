defmodule Exchange.Order do
  @moduledoc """
  A struct representing an Order to be placed in the Exchange

  side: :buy, :sell
  type: :market, :limit

  trader_id: Alchemist or the user_id
  expiration_time: unix timestamp in milliseconds when the order expires
  """
  defstruct order_id: nil,
            trader_id: nil,
            side: :buy,
            price: 0,
            size: 0,
            stop: 0,
            initial_size: 0,
            type: :market,
            exp_time: nil,
            acknowledged_at: DateTime.utc_now() |> DateTime.to_unix(:nanosecond),
            modified_at: DateTime.utc_now() |> DateTime.to_unix(:nanosecond),
            ticker: nil

  @type price_in_cents :: integer
  @type size_in_grams :: integer

  @type order :: %Exchange.Order{
          order_id: String.t(),
          trader_id: String.t(),
          side: atom,
          price: price_in_cents,
          size: size_in_grams,
          initial_size: size_in_grams,
          type: atom,
          ticker: atom,
          exp_time: integer | atom,
          stop: integer
        }

  @doc """
  Decodes the payload to an Order struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Order.order()
  def decode_from_jason(order) do
    ticker = Map.get(order, :ticker)

    ticker =
      if is_atom(ticker) do
        ticker
      else
        String.to_atom(ticker)
      end

    %Exchange.Order{
      order_id: Map.get(order, :order_id),
      trader_id: Map.get(order, :trader_id),
      side: Map.get(order, :side) |> String.to_atom(),
      price: Map.get(order, :price),
      size: Map.get(order, :size),
      stop: Map.get(order, :stop),
      initial_size: Map.get(order, :initial_size),
      type: Map.get(order, :type) |> String.to_atom(),
      exp_time: Map.get(order, :exp_time),
      acknowledged_at: Map.get(order, :acknowledged_at),
      modified_at: Map.get(order, :modified_at),
      ticker: ticker
    }
  end

  def assign_prices(%Exchange.Order{type: :market, side: side} = order, order_book) do
    if side == :buy do
      order |> Map.put(:price, order_book.max_price - 1)
    else
      order |> Map.put(:price, order_book.min_price + 1)
    end
  end

  def assign_prices(%Exchange.Order{type: :marketable_limit, side: side} = order, order_book) do
    if side == :buy do
      order |> Map.put(:price, order_book.ask_min)
    else
      order |> Map.put(:price, order_book.bid_max)
    end
  end

  def assign_prices(
        %Exchange.Order{type: :stop_loss, side: side, price: price, stop: stop} = order,
        order_book
      ) do
    if side == :buy do
      case order_book.ask_min >= price * (1 + stop / 100) do
        true ->
          order
          |> Map.put(:price, order_book.max_price - 1)

        _ ->
          order
      end
    else
      case order_book.bid_max <= price * (1 - stop / 100) do
        true ->
          order
          |> Map.put(:price, order_book.min_price + 1)

        _ ->
          order
      end
    end
  end

  def assign_prices(order, _order_book) do
    order
  end

  def validy_price(%Exchange.Order{type: type} = order, order_book)
      when type == :limit or type == :stop_loss do
    cond do
      order.price < order_book.max_price and order.price > order_book.min_price ->
        :ok

      order.price > order_book.max_price ->
        {:error, :max_price_exceeded}

      order.price < order_book.min_price ->
        {:error, :behind_min_price}
    end
  end

  def validy_price(_order, _order_book) do
    :ok
  end
end

defimpl Jason.Encoder, for: Exchange.Order do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order_id,
        :trader_id,
        :side,
        :price,
        :size,
        :stop,
        :initial_size,
        :type,
        :exp_time,
        :acknowledged_at,
        :modified_at,
        :ticker
      ]),
      opts
    )
  end
end
