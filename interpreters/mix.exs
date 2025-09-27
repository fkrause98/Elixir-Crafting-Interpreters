defmodule Interpreters.MixProject do
  use Mix.Project

  def project do
    [
      app: :interpreters,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [
        main_module: Lox
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      {:fix_warnings, "~> 0.1.0", only: :dev}
    ]
  end
end
