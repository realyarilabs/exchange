defmodule Exchange.MixProject do
  use Mix.Project

  def project do
    [
      app: :exchange,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Exchange.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:qex, "~> 0.5"},
      {:elixir_uuid, "~> 1.2"},
      {:typed_struct, "~> 0.2"},
      # {:event_bus, in_umbrella: true},
      # {:flux, in_umbrella: true},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_html, "~> 1.0", only: :dev}
    ]
  end
end
