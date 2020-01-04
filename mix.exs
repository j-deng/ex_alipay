defmodule ExAlipay.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_alipay,
      version: "0.1.1",
      elixir: "~> 1.5",
      name: "ExAlipay",
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/j-deng/ex_alipay",
      docs: [
        main: "ExAlipay.Client",
        extras: ["README.md"]
      ]
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
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.4"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp description do
    "An alipay client for Elixir"
  end

  defp package do
    [
      maintainers: ["j-deng"],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/j-deng/ex_alipay"
      }
    ]
  end
end
