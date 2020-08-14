defmodule Exchange do
  @moduledoc """
  The best Elixir Exchange supporting limit and market orders. Restful API and fancy dashboard supported soon!
  """

  @doc """
  Places an order on the Exchange

  ## Parameters

    - order_params: Map that represents the parameters of the order to be placed
    - ticker: Atom that represents on which market the order should be placed

  """
  @spec place_order(order_params :: map(), ticker :: atom()) :: atom() | {atom(), String.t()}
  def place_order(%{type: :limit} = order_params, ticker) do
    order_params = Map.put(order_params, :ticker, ticker)

    case Exchange.Validations.cast_order(order_params) do
      {:ok, limit_order} ->
        Exchange.MatchingEngine.place_limit_order(ticker, limit_order)

      {:error, errors} ->
        {:error, errors}
    end
  end

  def place_order(%{type: :market} = order_params, ticker) do
    order_params = Map.put(order_params, :ticker, ticker)

    case Exchange.Validations.cast_order(order_params) do
      {:ok, market_order} ->
        Exchange.MatchingEngine.place_market_order(ticker, market_order)

      {:error, errors} ->
        {:error, errors}
    end
  end

  def place_order(%{type: :marketable_limit} = order_params, ticker) do
    order_params = Map.put(order_params, :ticker, ticker)

    case Exchange.Validations.cast_order(order_params) do
      {:ok, marketable_limit_order} ->
        Exchange.MatchingEngine.place_marketable_limit_order(ticker, marketable_limit_order)

      {:error, errors} ->
        {:error, errors}
    end
  end

  @doc """
  Cancels an order on the Exchange

  ## Parameters

    - order_id: String that represents the id of the order to cancel
    - ticker: Atom that represents on which market the order should be canceled
  """
  @spec cancel_order(order_id :: String.t(), ticker :: atom) :: atom
  def cancel_order(order_id, ticker) do
    Exchange.MatchingEngine.cancel_order(ticker, order_id)
  end

  # Level 1 Market Data
  @doc """
  Returns the difference between the lowest sell order and the highest buy order

  ## Parameters

    - ticker: Atom that represents on which market the order should be canceled
  """
  @spec spread(ticker :: atom) :: {atom, number}
  def spread(ticker) do
    Exchange.MatchingEngine.spread(ticker)
  end

  @doc """
  Returns the highest price of all buy orders

  ## Parameters

    - ticker: Atom that represents on which market the query should be placed
  """
  @spec highest_bid_price(ticker :: atom) :: {atom, number}
  def highest_bid_price(ticker) do
    Exchange.MatchingEngine.bid_max(ticker)
  end

  @doc """
  Returns the sum of all active buy order's size

  ## Parameters

    - ticker: Atom that represents on which market the query should be placed
  """
  @spec highest_bid_volume(ticker :: atom) :: {atom, number}
  def highest_bid_volume(ticker) do
    Exchange.MatchingEngine.bid_volume(ticker)
  end

  @doc """
  Returns the lowest price of all sell orders

  ## Parameters

    - ticker: Atom that represents on which market the query should be placed
  """
  @spec lowest_ask_price(ticker :: atom) :: {atom, number}
  def lowest_ask_price(ticker) do
    Exchange.MatchingEngine.ask_min(ticker)
  end

  @doc """
  Returns the sum of all active sell order's size

  ## Parameters

    - ticker: Atom that represents on which market the query should be placed
  """
  @spec highest_ask_volume(ticker :: atom) :: {atom, number}
  def highest_ask_volume(ticker) do
    Exchange.MatchingEngine.ask_volume(ticker)
  end

  @doc """
  Returns a list of all active orders

  ## Parameters

    - order_id: String that represents the id of the order to cancel
    - ticker: Atom that represents on which market the query should be placed
  """
  @spec open_orders(ticker :: atom) :: {atom, list}
  def open_orders(ticker) do
    Exchange.MatchingEngine.open_orders(ticker)
  end

  @doc """
  Returns a list of active orders placed by the trader

  ## Parameters

    - ticker: Atom that represents on which market the query should be made
    - trader_id: String that represents the id of the traderd
  """
  @spec open_orders_by_trader(ticker :: atom, trader_id :: String.t()) :: {atom, list}
  def open_orders_by_trader(ticker, trader_id) do
    Exchange.MatchingEngine.open_orders_by_trader(ticker, trader_id)
  end

  def last_price do
  end

  def last_size do
  end

  @doc """
  Returns a list of completed trades where the trader is one of the participants

  ## Parameters

    - ticker: Atom that represents on which market the query should be made
    - trader_id: String that represents the id of the trader
  """
  @spec completed_trades_by_id(ticker :: atom, trader_id :: String.t() | atom()) :: [
          Exchange.Trade
        ]
  def completed_trades_by_id(ticker, trader_id) when is_atom(trader_id) do
    completed_trades_by_id(ticker, Atom.to_string(trader_id))
  end

  def completed_trades_by_id(ticker, trader_id) do
    Exchange.Utils.fetch_completed_trades(ticker, trader_id)
  end

  @doc """
  Returns the number of active buy orders

  ## Parameters

    - ticker: Atom that represents on which market the query should made
  """
  @spec total_buy_orders(ticker :: atom) :: {atom, number}
  def total_buy_orders(ticker) do
    Exchange.MatchingEngine.total_bid_orders(ticker)
  end

  @doc """
  Returns the number of active sell orders

  ## Parameters

    - ticker: Atom that represents on which market the query should made
  """
  @spec total_sell_orders(ticker :: atom) :: {atom, number}
  def total_sell_orders(ticker) do
    Exchange.MatchingEngine.total_ask_orders(ticker)
  end
end
