defmodule Exchange.MixProject do
  use Mix.Project

  def project do
    [
      app: :exchange,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
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
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_html, "~> 1.0", only: :dev},
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mox, "~> 0.5.1", only: :test},
      {:money, "~> 1.7"}
    ]
  end

  defp description do
    "The best Elixir Exchange supporting limit and market orders. Restful API and fancy dashboard supported soon!"
  end

  defp package do
    [
      files: ~w(lib test tasks .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      # licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/realyarilabs/alchemist_exchange"}
    ]
  end
end
