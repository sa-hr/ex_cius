defmodule ExCius.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_cius,
      version: "0.2.1",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "ExCius",
      source_url: "https://github.com/sa-hr/ex_cius",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:xmerl, :logger]
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:xmerl_c14n, "~> 0.1.0"},
      {:xml_builder, "~> 2.1"},
      {:sweet_xml, "~> 0.7"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.2"}
    ]
  end

  defp description do
    "Library for creating invoices under the Croatian e-Invoice (CIUS) standard"
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/sa-hr/ex_cius"}
    ]
  end
end
