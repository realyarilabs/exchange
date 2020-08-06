defmodule AlchemistExchange.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Exchange",
      source_url: "https://github.com/realyarilabs/alchemist_exchange",
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
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
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      # licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/realyarilabs/alchemist_exchange"}
    ]
  end
end
