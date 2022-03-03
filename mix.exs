defmodule IVCUS3Storage.MixProject do
  use Mix.Project

  def project do
    [
      app: :ivcu_s3_storage,
      version: "0.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [dialyzer: :test],

      # Dialyzer.
      dialyzer: [
        plt_add_apps: [:mix],
        remove_defaults: [:unknown]
      ],

      # Docs.
      name: "IVCU S3 Storage",
      docs: docs(),

      # Package.
      description: description(),
      package: package()
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
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :test, runtime: false},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:hackney, "~> 1.9"},
      {:ivcu, "~> 0.1"},
      {:sweet_xml, "~> 0.7"}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/elixir-ivcu/ivcu_s3_storage",
      source_ref: "master",
      extras: ["guides/getting_started.md"]
    ]
  end

  defp description do
    "S3 storage for IVCU."
  end

  defp package do
    [
      links: %{"GitHub" => "https://github.com/elixir-ivcu/ivcu_s3_storage"},
      licenses: ["Apache-2.0"],
      files: ~w[mix.exs LICENSE README.md lib guides]
    ]
  end
end
