defmodule Exchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Registry, [:unique, :matching_engine_registry]),

      # create a supervised Matching Enginge for AUXLND, AUXZUR
      supervisor(
        Exchange.MatchingEngine,
        [[ticker: :AUXLND, currency: :GBP, min_price: 1000, max_price: 99_000]],
        id: :AUXLND
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exchange.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
