defmodule ExchangeWeb.PageController do
  use ExchangeWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "** shrug **"})
  end
end
