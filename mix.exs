defmodule Exchange.MixProject do
  use Mix.Project

  def project do
    [
      app: :exchange,
      version: "0.2.6",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Exchange",
      source_url: "https://github.com/realyarilabs/exchange",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      xref: [exclude: [AMQP]],
      description: description(),
      package: package()
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
      {:benchee, "~> 1.0", only: :dev, optional: true},
      {:benchee_html, "~> 1.0", only: :dev, optional: true},
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false, optional: true},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false, optional: true},
      {:excoveralls, "~> 0.10", only: :test, optional: true},
      {:mox, "~> 1.0.0", only: :test, optional: true},
      {:instream, "~> 1.0", optional: true},
      {:amqp, "~> 1.0", optional: true},
      {:money, "~> 1.7"},
      {:qex, "~> 0.5"},
      {:elixir_uuid, "~> 1.2"},
      {:typed_struct, "~> 0.2"}
    ]
  end

  defp description do
    "The best Elixir Exchange supporting limit and market orders. Restful API and fancy dashboard supported soon!"
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/realyarilabs/exchange"}
    ]
  end
end
