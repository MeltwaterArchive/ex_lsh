defmodule ExLSH.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_lsh,
      description: description(),
      version: "0.2.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      name: "ExLSH",
      source_url: "https://github.com/meltwater/ex_lsh",
      homepage_url: "https://hexdocs.pm/ex_lsh",
      docs: [
        main: "ExLSH",
        extras: ["README.md"]
      ],

      package: package(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:matrex, git: "https://github.com/versilov/matrex.git", ref: "7abf3fdb79dd1fad8aa077d00e3ff96d4c21ea4e"},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
    ]
  end

  defp description() do
    "ExLSH calculates a locality sensitive hash for text. It can be used for near-dupclicate detection for text."
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{ "GitHub" => "https://github.com/meltwater/ex_lsh" },
      organization: "meltwater",
    ]
  end
end
