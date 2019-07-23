defmodule ExAlipay.Utils do
  @moduledoc """
  ExAlipay Utils.
  """
  alias ExAlipay.{Client, RSA}

  @doc """
  Create sign of request params map or sign_str.
  """
  @spec create_sign(%Client{}, map | binary) :: binary
  def create_sign(client, params) when is_map(params) do
    create_sign(client, create_sign_str(params))
  end
  def create_sign(client, sign_str) when is_binary(sign_str) do
    RSA.sign(sign_str, client.sign_type, client.private_key)
  end

  @doc """
  Create sign_str of request params map.
  """
  @spec create_sign_str(map) :: binary
  def create_sign_str(params) do
    params
    |> Map.keys
    |> Enum.sort
    |> Enum.map(fn k -> "#{k}=#{params[k]}" end)
    |> Enum.join("&")
  end

  @doc """
  Build request url with gatway.
  """
  @spec  build_request_str(%Client{}, binary, map | nil, map) :: binary
  def build_request_url(client, method, content, ext_params) do
    gateway = get_gateway(client)
    trade_str = build_request_str(client, method, content, ext_params)
    "#{gateway}?#{trade_str}"
  end

  @doc """
  Build trade str without gateway.
  """
  @spec  build_request_str(%Client{}, binary, map | nil, map) :: binary
  def build_request_str(client, method, content, ext_params) do
    params =
      %{
        app_id: client.appid,
        version: client.version,
        format: client.format,
        charset: client.charset,
        sign_type: client.sign_type,
        method: method,
        timestamp: create_timestamp(),
      }
      |> Map.merge(filter_nil(ext_params))

    params = case content do
      nil ->
        params
      _ ->
        biz_content = content |> filter_nil |> Jason.encode!
        Map.put(params, :biz_content, biz_content)
      end

    params
    |> Map.put(:sign, create_sign(client, params))
    |> URI.encode_query
  end

  def get_gateway(%Client{sandbox?: false}) do
    "https://openapi.alipay.com/gateway.do"
  end
  def get_gateway(%Client{sandbox?: true}) do
    "https://openapi.alipaydev.com/gateway.do"
  end

  defp create_timestamp do
    :calendar.local_time
    |> NaiveDateTime.from_erl!
    |> NaiveDateTime.to_string
  end

  defp filter_nil(a_map) when is_map(a_map) do
    :maps.filter(fn _, val -> not is_nil(val) end, a_map)
  end
end
