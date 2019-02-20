defmodule ExLSH.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_lsh,
      aliases: aliases(),
      description: description(),
      version: "0.4.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExLSH",
      source_url: "https://github.com/meltwater/ex_lsh",
      homepage_url: "https://hexdocs.pm/ex_lsh",
      docs: [
        main: "ExLSH",
        extras: ["README.md"]
      ],
      package: package()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description() do
    "ExLSH calculates a locality sensitive hash for text. It can be used for near-dupclicate detection for text."
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/meltwater/ex_lsh"}
    ]
  end

  defp aliases do
    [
      test: [
        "format --check-formatted",
        "credo --strict",
        "test"
      ]
    ]
  end
end
