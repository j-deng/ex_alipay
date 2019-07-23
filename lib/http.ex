defmodule ExAlipay.HTTP.Behaviour do
  @typep url :: binary()
  @callback get(url) :: {:ok, map()} | {:error, binary() | map()}
end
