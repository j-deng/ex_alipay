use Mix.Config

config :ex_alipay,
  http_adapter: HTTPoison

if Mix.env() == :test do
  import_config "test.exs"
end
