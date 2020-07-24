defmodule EventBus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # From https://hexdocs.pm/elixir/Registry.html#content
    # set the number of partitions to the number of schedulers online wich
    # will make the registry more performant on highly concurrent env
    children = [
      {Registry,
       keys: :duplicate, name: EventBus.Registry, partitions: System.schedulers_online()}
    ]

    opts = [strategy: :one_for_one, name: EventBus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
