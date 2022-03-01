defmodule IVCUS3Storage.MixProject do
  use Mix.Project

  def project do
    [
      app: :ivcu_s3_storage,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
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
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:hackney, "~> 1.9"},
      {:ivcu, git: "https://github.com/elixir-ivcu/ivcu", tag: "v0.1.0"},
      {:sweet_xml, "~> 0.7"}
    ]
  end

  defp docs do
    [extras: ["guides/getting_started.md"]]
  end
end
