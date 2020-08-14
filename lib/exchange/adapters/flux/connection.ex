defmodule Exchange.Adapters.Flux.Connection do
  @moduledoc """
  Connection config to influxdb
  """

  use Instream.Connection, otp_app: :flux
end
