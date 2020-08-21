defmodule OrderBookTest do
  use ExUnit.Case
  alias Exchange.{OrderBook, Utils}

  describe "sample order book created with price time match" do
    setup _context do
      ticker = :AUXLND
      {:ok, %{order_book: Utils.sample_order_book(ticker), ticker: ticker}}
    end

    test "has defaults name and currency", %{order_book: ob, ticker: ticker} do
      assert ob.name == ticker
      assert ob.currency == :GBP
    end

    test "has expected minimum ask and highest bid", %{order_book: ob} do
      assert ob.ask_min == 4010
      assert ob.bid_max == 4000
      assert ob.min_price == 1000
      assert ob.max_price == 100_000
    end

    test "spread", %{order_book: order_book} do
      assert OrderBook.spread(order_book) == 10
    end

    test "has correct index order_ids", %{order_book: ob} do
      list_of_all_ids = ~w(1 2 3 4 5 6 7 8)
      assert Map.keys(ob.order_ids) == list_of_all_ids
      assert ob.order_ids["1"] == {:sell, 4010}
      assert ob.order_ids["2"] == {:buy, 3970}
      assert ob.order_ids["7"] == {:buy, 3960}
      assert ob.order_ids["8"] == {:sell, 4010}
    end

    test "has correct price points", %{order_book: ob} do
      assert Map.keys(ob.buy) == [3960, 3970, 4000]
      assert Map.keys(ob.sell) == [4010, 4020]
    end

    test "has correct FIFO order for given price_point", %{order_book: ob} do
      ids_sell_queue_4010 =
        ob.sell[4010]
        |> Enum.map(fn order -> order.order_id end)

      ids_buy_queue_4000 =
        ob.buy[4000]
        |> Enum.map(fn order -> order.order_id end)

      assert ids_sell_queue_4010 == ~w(1 5 8)
      assert ids_buy_queue_4000 == ~w(4 6)
    end

    test "with no matching orders returns empty trades", %{order_book: ob} do
      assert ob.completed_trades == []
    end
  end

  describe "expirations" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND)}}
    end

    test "orders with expiration are added to expiration_list", %{order_book: ob} do
      t1 = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      t2 = (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - 1000

      buy_order =
        Utils.sample_expiring_order(%{size: 1000, price: 3999, side: :buy, id: "9", exp_time: t1})

      sell_order =
        Utils.sample_expiring_order(%{
          size: 1000,
          price: 4020,
          side: :sell,
          id: "10",
          exp_time: t2
        })

      new_book = OrderBook.price_time_match(ob, buy_order)
      new_book = OrderBook.price_time_match(new_book, sell_order)
      order_id_1 = buy_order.order_id
      order_id_2 = sell_order.order_id

      assert new_book.expiration_list == [{t2, order_id_2}, {t1, order_id_1}]
    end

    test "orders fullfilled are not added to expiration_list", %{order_book: ob} do
      t1 = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      buy_order =
        Utils.sample_expiring_order(%{size: 750, price: 4010, side: :buy, id: "9", exp_time: t1})

      new_book = OrderBook.price_time_match(ob, buy_order)
      assert new_book.expiration_list == []
    end

    test "order is automatically cancelled on expiration time", %{order_book: ob} do
      t = (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - 1

      order =
        Utils.sample_expiring_order(%{size: 1000, price: 3999, side: :buy, id: "9", exp_time: t})

      new_book = OrderBook.price_time_match(ob, order)
      assert [{t, order.order_id}] == new_book.expiration_list

      new_book = OrderBook.check_expired_orders!(new_book)
      assert new_book.expired_orders == [order]
    end

    test "flushing expired orders from order_book", %{order_book: ob} do
      t = (DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - 1

      order =
        Utils.sample_expiring_order(%{size: 1000, price: 3999, side: :buy, id: "9", exp_time: t})

      new_book = ob |> OrderBook.price_time_match(order) |> OrderBook.check_expired_orders!()
      assert [order] == new_book.expired_orders
      new_book_with_flushed_expired = OrderBook.flush_expired_orders!(new_book)
      assert new_book_with_flushed_expired.expired_orders == []
    end
  end

  describe "new entry on OrderBook without match" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND)}}
    end

    test "buy order at top of the order book", %{order_book: ob} do
      top_buy_order = Utils.sample_order(%{size: 1000, price: 4005, side: :buy})
      new_book = OrderBook.price_time_match(ob, top_buy_order)
      assert new_book.completed_trades == []
      assert new_book.order_ids["9"] == {:buy, 4005}
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4005
    end

    test "buy order at middle of the order book", %{order_book: ob} do
      buy_order = Utils.sample_order(%{size: 1000, price: 3970, side: :buy})
      new_book = OrderBook.price_time_match(ob, buy_order)
      new_price_level_queue = new_book.buy[3970]

      assert new_book.completed_trades == []
      assert new_book.order_ids["9"] == {:buy, 3970}
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
      # new sell order is last on the queue
      assert Enum.map(new_price_level_queue, & &1.order_id) == ["2", "9"]
    end

    test "sell order at top of the order book", %{order_book: ob} do
      top_sell_order = Utils.sample_order(%{size: 1000, price: 4007, side: :sell})
      new_book = OrderBook.price_time_match(ob, top_sell_order)
      assert new_book.completed_trades == []
      assert new_book.order_ids["9"] == {:sell, 4007}
      assert new_book.ask_min == 4007
      assert new_book.bid_max == 4000
    end

    test "sell order at middle of the order book", %{order_book: ob} do
      sell_order = Utils.sample_order(%{size: 1000, price: 4020, side: :sell})
      new_book = OrderBook.price_time_match(ob, sell_order)
      new_price_level_queue = new_book.sell[4020]

      assert new_book.completed_trades == []
      assert new_book.order_ids["9"] == {:sell, 4020}
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
      # new sell order is last on the queue
      assert Enum.map(new_price_level_queue, & &1.order_id) == ["3", "9"]
    end
  end

  describe "single trade against oposite order at top of the order book" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND)}}
    end

    test "buy order has the exact same size", %{order_book: ob} do
      buy_order = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      buy_order = %{buy_order | ticker: :AUXLND}
      new_book = OrderBook.price_time_match(ob, buy_order)
      [trade] = new_book.completed_trades

      assert %Exchange.Trade{
               buy_init_size: 750,
               sell_init_size: 750,
               size: 750,
               price: 4010,
               type: :full_fill,
               buy_order_id: "9",
               buyer_id: "alchemist9",
               seller_id: "alchemist5",
               sell_order_id: "1",
               ticker: :AUXLND,
               currency: :GBP
             } = trade

      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
      refute OrderBook.fetch_order_by_id(new_book, "1")
      refute new_book.order_ids["1"]
    end

    test "sell order has exact same size", %{order_book: ob} do
      sell_order = Utils.sample_order(%{size: 250, price: 4000, side: :sell})
      sell_order = %{sell_order | ticker: :AUXLND}
      new_book = OrderBook.price_time_match(ob, sell_order)
      [trade] = new_book.completed_trades

      assert %Exchange.Trade{
               buy_init_size: 250,
               sell_init_size: 250,
               size: 250,
               price: 4000,
               type: :full_fill,
               buy_order_id: "4",
               seller_id: "alchemist9",
               buyer_id: "alchemist1",
               sell_order_id: "9",
               ticker: :AUXLND,
               currency: :GBP
             } = trade

      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
      refute OrderBook.fetch_order_by_id(new_book, "4")
      refute new_book.order_ids["4"]
    end

    test "buy order has lower size", %{order_book: ob} do
      buy_order = Utils.sample_order(%{size: 500, price: 4010, side: :buy})
      new_book = OrderBook.price_time_match(ob, buy_order)
      remaining_sell_order = OrderBook.fetch_order_by_id(new_book, "1")

      assert [
               %Exchange.Trade{
                 buy_init_size: 500,
                 sell_init_size: 750,
                 size: 500,
                 price: 4010,
                 type: :full_fill,
                 buy_order_id: "9",
                 buyer_id: "alchemist9",
                 seller_id: "alchemist5",
                 sell_order_id: "1"
               }
             ] = new_book.completed_trades

      assert remaining_sell_order.size == 250
      assert new_book.order_ids["1"] == {:sell, 4010}
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
    end

    test "sell order has lower size", %{order_book: ob} do
      sell_order = Utils.sample_order(%{size: 200, price: 4000, side: :sell})
      new_book = OrderBook.price_time_match(ob, sell_order)
      remaining_buy_order = OrderBook.fetch_order_by_id(new_book, "4")

      assert [
               %Exchange.Trade{
                 buy_init_size: 250,
                 sell_init_size: 200,
                 size: 200,
                 price: 4000,
                 type: :full_fill,
                 buy_order_id: "4",
                 seller_id: "alchemist9",
                 buyer_id: "alchemist1",
                 sell_order_id: "9"
               }
             ] = new_book.completed_trades

      assert remaining_buy_order.size == 50
      assert new_book.order_ids["4"] == {:buy, 4000}
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
    end

    test "consuming sell side then consume buy side", %{order_book: order_book} do
      new_order_increment = Utils.sample_order(%{size: 2350, price: 99_999, side: :buy})
      new_order_decrement = Utils.sample_order(%{size: 1850, price: 1001, side: :sell})
      new_order_book = OrderBook.price_time_match(order_book, new_order_increment)
      assert new_order_book.bid_max == 99_999
      assert new_order_book.ask_min == 99_999
      new_order_book2 = OrderBook.price_time_match(new_order_book, new_order_decrement)
      assert new_order_book2.bid_max == 1001
      assert new_order_book2.ask_min == 1001
    end

    test "consume sell side with one order", %{order_book: order_book} do
      new_order_increment = Utils.sample_order(%{size: 2350, price: 5000, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order_increment)
      assert new_order_book.bid_max == 5000
      assert new_order_book.ask_min == 99_999
    end

    test "consume buy side with one order", %{order_book: order_book} do
      new_order_decrement = Utils.sample_order(%{size: 1750, price: 1001, side: :sell})
      new_order_book = OrderBook.price_time_match(order_book, new_order_decrement)
      assert new_order_book.bid_max == 1001
      assert new_order_book.ask_min == 1001
      assert Enum.count(new_order_book.completed_trades) == 4
    end
  end

  describe "multiple trades with order of exact size of more then 2 orders" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND), ticker: :AUXLND}}
    end

    test "buy order size is equal to all orders at top of orderbook", %{order_book: ob} do
      buy_order = Utils.sample_order(%{size: 2000, price: 4010, side: :buy})
      new_book = OrderBook.price_time_match(ob, buy_order)
      trades = new_book.completed_trades
      total_size = trades |> Enum.reduce(0, fn t, acc -> t.size + acc end)

      buyer_details =
        trades
        |> Enum.map(fn t ->
          {t.buyer_id, t.buy_init_size, t.buy_order_id, t.currency, t.price}
        end)
        |> Enum.uniq()

      refute OrderBook.fetch_order_by_id(new_book, "1")
      refute OrderBook.fetch_order_by_id(new_book, "5")
      refute OrderBook.fetch_order_by_id(new_book, "8")
      assert Enum.count(new_book.completed_trades) == 3
      assert [{"alchemist9", 2000, "9", :GBP, 4010}] == buyer_details
      assert total_size == buy_order.initial_size
      assert new_book.ask_min == 4020
      assert new_book.bid_max == 4000
    end

    test "sell order size is equal to all orders at top of orderbook", %{order_book: ob} do
      sell_order = Utils.sample_order(%{size: 750, price: 4000, side: :sell})
      new_book = OrderBook.price_time_match(ob, sell_order)
      trades = new_book.completed_trades
      total_size = trades |> Enum.reduce(0, fn t, acc -> t.size + acc end)

      seller_details =
        trades
        |> Enum.map(fn t ->
          {t.seller_id, t.sell_init_size, t.sell_order_id, t.currency, t.price}
        end)
        |> Enum.uniq()

      refute OrderBook.fetch_order_by_id(new_book, "4")
      refute OrderBook.fetch_order_by_id(new_book, "6")
      assert Enum.count(new_book.completed_trades) == 2
      assert [{"alchemist9", 750, "9", :GBP, 4000}] == seller_details
      assert total_size == sell_order.initial_size
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 3970
    end

    test "if more then one trade they're all type: partial_fill", %{order_book: ob} do
      new_order = Utils.sample_order(%{size: 2000, price: 4010, side: :buy})

      trades =
        ob
        |> OrderBook.price_time_match(new_order)
        |> Map.get(:completed_trades)

      assert Enum.all?(trades, &(&1.type == :partial_fill)) == true
    end
  end

  describe "multiple trades with order of HIGHER size then top of orderbook" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND), ticker: :AUXLND}}
    end

    test "buy order size is HIGHER then all orders at price level", %{order_book: ob} do
      buy_order = Utils.sample_order(%{size: 2100, price: 4010, side: :buy})
      new_book = OrderBook.price_time_match(ob, buy_order)
      trades = new_book.completed_trades
      total_size = trades |> Enum.reduce(0, fn t, acc -> t.size + acc end)
      remaining_buy_order = OrderBook.fetch_order_by_id(new_book, "9")

      refute OrderBook.fetch_order_by_id(new_book, "1")
      refute OrderBook.fetch_order_by_id(new_book, "5")
      refute OrderBook.fetch_order_by_id(new_book, "8")
      assert Enum.count(new_book.completed_trades) == 3

      assert total_size == buy_order.initial_size - 100
      assert remaining_buy_order.size == 100
      assert new_book.bid_max == 4010
      assert new_book.ask_min == 4020
    end

    test "sell order size is HIGHER then all orders at price level", %{order_book: ob} do
      sell_order = Utils.sample_order(%{size: 800, price: 4000, side: :sell})
      new_book = OrderBook.price_time_match(ob, sell_order)
      trades = new_book.completed_trades
      total_size = trades |> Enum.reduce(0, fn t, acc -> t.size + acc end)
      remaining_sell_order = OrderBook.fetch_order_by_id(new_book, "9")

      refute OrderBook.fetch_order_by_id(new_book, "4")
      refute OrderBook.fetch_order_by_id(new_book, "6")
      assert Enum.count(new_book.completed_trades) == 2

      assert total_size == sell_order.initial_size - 50
      assert remaining_sell_order.size == 50
      assert new_book.ask_min == 4000
      assert new_book.bid_max == 3970
    end
  end

  describe "cancelation" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND)}}
    end

    test "canceling a middle order book buy order", %{order_book: order_book} do
      cancelled_order = OrderBook.fetch_order_by_id(order_book, "2")
      new_book = OrderBook.dequeue_order_by_id(order_book, "2")

      refute OrderBook.fetch_order_by_id(new_book, "2")
      refute Map.has_key?(new_book.order_ids, "2")
      assert cancelled_order.order_id == "2"
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
    end

    test "canceling a middle order book sell order", %{order_book: order_book} do
      cancelled_order = OrderBook.fetch_order_by_id(order_book, "3")
      new_book = OrderBook.dequeue_order_by_id(order_book, "3")

      refute OrderBook.fetch_order_by_id(new_book, "3")
      refute Map.has_key?(new_book.order_ids, "3")
      assert cancelled_order.order_id == "3"
      assert new_book.ask_min == 4010
      assert new_book.bid_max == 4000
    end

    test "canceling all buy orders from price level top of order book", %{order_book: order_book} do
      new_book =
        order_book
        |> OrderBook.dequeue_order_by_id("4")
        |> OrderBook.dequeue_order_by_id("6")

      refute OrderBook.fetch_order_by_id(new_book, "4")
      refute OrderBook.fetch_order_by_id(new_book, "6")

      assert new_book.ask_min == 4010
      assert new_book.bid_max == 3970
    end

    test "canceling all sell orders from price level top of order book", %{order_book: order_book} do
      new_book =
        order_book
        |> OrderBook.dequeue_order_by_id("1")
        |> OrderBook.dequeue_order_by_id("5")
        |> OrderBook.dequeue_order_by_id("8")

      refute OrderBook.fetch_order_by_id(new_book, "1")
      refute OrderBook.fetch_order_by_id(new_book, "5")
      refute OrderBook.fetch_order_by_id(new_book, "8")

      assert new_book.bid_max == 4000
      assert new_book.ask_min == 4020
    end
  end

  describe "helper functions" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND)}}
    end

    test "flush_trades", %{order_book: order_book} do
      buy_order = Utils.sample_order(%{size: 2100, price: 4010, side: :buy})
      new_book = OrderBook.price_time_match(order_book, buy_order)
      book_with_flushed_trades = OrderBook.flush_trades!(new_book)

      assert Enum.count(new_book.completed_trades) == 3
      assert book_with_flushed_trades.completed_trades == []
    end
  end

  describe "queries" do
    setup _context do
      {:ok, %{order_book: Utils.sample_order_book(:AUXLND)}}
    end

    test "Bid volume default order_book", %{order_book: order_book} do
      assert OrderBook.highest_bid_volume(order_book) == 1650
    end

    test "Ask volume default order_book", %{order_book: order_book} do
      assert OrderBook.highest_ask_volume(order_book) == 2250
    end

    test "Bid total orders default order_book", %{order_book: order_book} do
      assert OrderBook.total_bid_orders(order_book) == 4
    end

    test "Ask total orders default order_book", %{order_book: order_book} do
      assert OrderBook.total_ask_orders(order_book) == 4
    end

    test "All open orders in default order_book", %{order_book: order_book} do
      assert Enum.count(OrderBook.open_orders(order_book)) == 8
    end

    test "All open orders by trader_id in default order_book", %{order_book: order_book} do
      assert Enum.count(OrderBook.open_orders_by_trader(order_book, "alchemist1")) == 1
      assert OrderBook.open_orders_by_trader(order_book, "foo") == []
    end

    test "Bid volume order_book after adding one buy order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 150, price: 3000, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.highest_bid_volume(new_order_book) == 1800
    end

    test "Ask volume order_book after adding one sell order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 150, price: 4010, side: :sell})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.highest_ask_volume(new_order_book) == 2400
    end

    test "Total bid orders in order_book after adding one buy order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 150, price: 3000, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.total_bid_orders(new_order_book) == 5
    end

    test "Total ask orders in order_book after adding one sell order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 150, price: 4010, side: :sell})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.total_ask_orders(new_order_book) == 5
    end

    test "All open orders in order_book after adding one order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 150, price: 3000, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert Enum.count(OrderBook.open_orders(new_order_book)) == 9
    end

    test "All open orders by trader_id after adding one order (not belonging to trader)", %{
      order_book: order_book
    } do
      new_order = Utils.sample_order(%{size: 150, price: 3000, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert Enum.count(OrderBook.open_orders_by_trader(new_order_book, "alchemist1")) == 1
    end

    test "Bid volume order_book after removal of one buy order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 150, price: 4000, side: :sell})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.highest_bid_volume(new_order_book) == 1500
    end

    test "Ask volume order_book after removal of one sell order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.highest_ask_volume(new_order_book) == 1500
    end

    test "Total bid orders in order_book after removal of one buy order", %{
      order_book: order_book
    } do
      new_order = Utils.sample_order(%{size: 500, price: 4000, side: :sell})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.total_bid_orders(new_order_book) == 3
    end

    test "Total ask orders in order_book after removal of one buy order", %{
      order_book: order_book
    } do
      new_order = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.total_ask_orders(new_order_book) == 3
    end

    test "All open orders in order_book after removal of one order", %{order_book: order_book} do
      new_order = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert Enum.count(OrderBook.open_orders(new_order_book)) == 7
    end

    test "All open orders by trader_id after removal of one order (belonging to trader)", %{
      order_book: order_book
    } do
      new_order = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order)
      assert OrderBook.open_orders_by_trader(new_order_book, "alchemist5") == []
    end

    test "Bid volume order_book after removal and addition of orders", %{order_book: order_book} do
      new_order_1 = Utils.sample_order(%{size: 500, price: 4000, side: :sell})
      new_order_2 = Utils.sample_order(%{size: 1000, price: 3900, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order_1)
      new_order_book = OrderBook.price_time_match(new_order_book, new_order_2)
      assert OrderBook.highest_bid_volume(new_order_book) == 2150
    end

    test "Ask volume order_book after removal and addition of orders", %{order_book: order_book} do
      new_order_1 = Utils.sample_order(%{size: 250, price: 4000, side: :sell})
      new_order_2 = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order_1)
      new_order_book = OrderBook.price_time_match(new_order_book, new_order_2)
      assert OrderBook.highest_ask_volume(new_order_book) == 1500
    end

    test "Total bid orders in order_book after removal and adittion of orders", %{
      order_book: order_book
    } do
      new_order_1 = Utils.sample_order(%{size: 500, price: 4000, side: :sell})
      new_order_2 = Utils.sample_order(%{size: 1000, price: 3900, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order_1)
      new_order_book = OrderBook.price_time_match(new_order_book, new_order_2)
      assert OrderBook.total_bid_orders(new_order_book) == 4
    end

    test "Total ask orders in order_book after removal and addition of orders", %{
      order_book: order_book
    } do
      new_order_1 = Utils.sample_order(%{size: 250, price: 4000, side: :sell})
      new_order_2 = Utils.sample_order(%{size: 750, price: 4010, side: :buy})
      new_order_book = OrderBook.price_time_match(order_book, new_order_1)
      new_order_book = OrderBook.price_time_match(new_order_book, new_order_2)
      assert OrderBook.total_ask_orders(new_order_book) == 3
    end
  end

  describe "empty order book" do
    setup _context do
      {:ok, %{order_book: Utils.empty_order_book()}}
    end

    test "Empty order book", %{order_book: order_book} do
      order = Utils.sample_order(%{size: 1, price: order_book.max_price - 1, side: :buy})
      order_book = Exchange.OrderBook.price_time_match(order_book, order)
      assert order_book.ask_min == 99_999
      assert order_book.bid_max == 99_999
    end
  end
end
