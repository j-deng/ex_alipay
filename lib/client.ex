defmodule ExAlipay.Client do
  @moduledoc """
  ExAlipay Client that export API and perform request to alipay backend.

  This module defined some common used api and you can easily add new api:
    * `page_pay` - alipay.trade.page.pay
    * `wap_pay` - alipay.trade.wap.pay
    * `app_pay` - alipay.trade.app.pay
    * `query` - alipay.trade.query
    * `refund` - alipay.trade.refund
    * `close` - alipay.trade.close
    * `refund_query` - alipay.trade.fastpay.refund.query
    * `bill_downloadurl_query` - alipay.data.dataservice.bill.downloadurl.query
    * `auth_token` - alipay.system.oauth.token
    * `user_info` - alipay.user.info.share
    * `transfer` - alipay.fund.trans.toaccount.transfer
    * `transfer_query` - alipay.fund.trans.order.query

  ### Example Usage:

  Define a module `AlipayClient` that use `ExAlipay.Client`,
  `AlipayClient` module will define new functions that calling
  the same `ExAlipay.Client` functions, the difference is that it
  stores the client with module property `@client` for convenient:

  ```elixir
  defmodule AlipayClient do
    use ExAlipay.Client, Application.fetch_env!(:my_app, __MODULE__)
  end
  ```

  Config your `AlipayClient` in `config/config.exs`:

  ```elixir
  config :my_app, AlipayClient,
    appid: "APPID",
    pid: "PID",
    public_key: "-- public_key --",
    private_key: "-- private_key --",
    sandbox?: false
  ```

  Use the `page_pay`:

  ```elixir
  AlipayClient.page_pay(%{
    out_trade_no: "out_trade_no",
    total_amount: 100,
    subject: "the subject",
    return_url: "http://example.com/return_url",
    notify_url: "http://example.com/notify_url",
  })
  ```

  IN the handler view of alipay notify:

  ```elixir
  if AlipayClient.verify_notify_sign?(body) do
    # process the payment success logic
    # ...
    # response a plain text `success` to alipay
  else
    # response with error
  end
  ```

  Extend new api you need that not in `ExAlipay.Client`.

  ```elixir
  defmodule AlipayClient do
    use ExAlipay.Client, Application.fetch_env!(:my_app, __MODULE__)

    # access the public api request that defined in ExAlipay.Client
    # also possible to use functions in ExAlipay.Utils directly
    # see: https://docs.open.alipay.com/api_1/alipay.trade.precreate
    def pre_create(params), do: request(@client, "alipay.trade.precreate", params)
  end

  # now we can use the new api
  # AlipayClient.pre_create(%{})
  ```
  """
  alias ExAlipay.{Client, RSA, Utils}
  alias ExAlipay.{RequestError, ResponseError}

  @http_adapter Application.get_env(:ex_alipay, :http_adapter)

  defstruct appid: nil,
            public_key: nil,
            private_key: nil,
            pid: nil,
            format: "JSON",
            charset: "utf-8",
            sign_type: "RSA2",
            version: "1.0",
            sandbox?: false

  @type t :: %__MODULE__{
          appid: binary,
          public_key: binary,
          private_key: binary,
          pid: binary,
          format: binary,
          charset: binary,
          sign_type: binary,
          version: binary,
          sandbox?: boolean
        }

  @supported_api %{
    page_pay: "alipay.trade.page.pay",
    wap_pay: "alipay.trade.wap.pay",
    app_pay: "alipay.trade.app.pay",
    query: "alipay.trade.query",
    refund: "alipay.trade.refund",
    close: "alipay.trade.close",
    refund_query: "alipay.trade.fastpay.refund.query",
    bill_downloadurl_query: "alipay.data.dataservice.bill.downloadurl.query",
    auth_token: "alipay.system.oauth.token",
    user_info: "alipay.user.info.share",
    transfer: "alipay.fund.trans.toaccount.transfer",
    transfer_query: "alipay.fund.trans.order.query"
  }

  defmacro __using__(opts) do
    quote do
      import Client
      @before_compile Client
      @client Map.merge(%Client{}, Map.new(unquote(opts)))
    end
  end

  defmacro __before_compile__(_) do
    exist_functions = Client.__info__(:functions)

    supported_api()
    |> Map.keys()
    |> Enum.filter(fn key -> Keyword.has_key?(exist_functions, key) end)
    |> Enum.concat([:auth_url, :app_auth_str, :verify_notify_sign?])
    |> Enum.map(fn key ->
      quote do
        def unquote(key)(params), do: unquote(key)(@client, params)
      end
    end)
  end

  @doc false
  def supported_api, do: @supported_api

  @doc """
  Create trade url for web page.

  See: https://docs.open.alipay.com/270/alipay.trade.page.pay

  ## Examples:

      ExAlipay.Client.page_pay(client, %{
        out_trade_no: "out_trade_no",
        total_amount: 100,
        subject: "the subject",
        return_url: "http://example.com/return_url",
        notify_url: "http://example.com/notify_url",
      })
  """
  def page_pay(client, params) do
    params = Map.put_new(params, :product_code, "FAST_INSTANT_TRADE_PAY")
    {params, ext_params} = prepare_trade_params(params)
    Utils.build_request_url(client, @supported_api.page_pay, params, ext_params)
  end

  @doc """
  Create trade url for mobile page.

  See: https://docs.open.alipay.com/203/107090/
  """
  def wap_pay(client, params) do
    params = Map.put_new(params, :product_code, "QUICK_WAP_WAY")
    {params, ext_params} = prepare_trade_params(params)
    Utils.build_request_url(client, @supported_api.wap_pay, params, ext_params)
  end

  @doc """
  Create trade string for app pay.

  See: https://docs.open.alipay.com/204/105465/

  ## Examples:

      ExAlipay.Client.app_pay(client, %{
        out_trade_no: "out_trade_no",
        total_amount: 100,
        subject: "the subject",
        notify_url: "http://example.com/notify_url",
      })
  """
  def app_pay(client, params) do
    params = Map.put_new(params, :product_code, "QUICK_MSECURITY_PAY")
    {params, ext_params} = prepare_trade_params(params)
    Utils.build_request_str(client, @supported_api.app_pay, params, ext_params)
  end

  @doc """
  Pop `return_url` and `notify_url` from create trade params as ext_params.

  ## Examples:

      params = %{
        out_trade_no: "out_trade_no",
        total_amount: 100,
        subject: "the subject",
        notify_url: "http://example.com/notify_url",
      }

      ExAlipay.Client.prepare_trade_params(params)
      # Result:
      # {
      #   %{out_trade_no: "out_trade_no", subject: "the subject", total_amount: 100},
      #   %{notify_url: "http://example.com/notify_url", return_url: nil}
      # }
  """
  def prepare_trade_params(params) do
    {return_url, params} = Map.pop(params, :return_url)
    {notify_url, params} = Map.pop(params, :notify_url)
    ext_params = %{return_url: return_url, notify_url: notify_url}
    {params, ext_params}
  end

  @doc """
  Refund trade.

  See: https://docs.open.alipay.com/api_1/alipay.trade.refund

  ## Examples:

      ExAlipay.Client.refund(client, %{
        out_trade_no: "out_trade_no",
        refund_amount: 100
      })
  """
  def refund(client, params) do
    request(client, @supported_api.refund, params)
  end

  @doc """
  Query trade info.

  See: https://docs.open.alipay.com/api_1/alipay.trade.query

  ## Examples:

      ExAlipay.Client.query(client, %{
        out_trade_no: "out_trade_no",
      })
  """
  def query(client, params) do
    request(client, @supported_api.query, params)
  end

  @doc """
  Close trade.

  See: https://docs.open.alipay.com/api_1/alipay.trade.close

  ## Examples:

      ExAlipay.Client.close(client, %{
        out_trade_no: "out_trade_no",
      })
  """
  def close(client, params) do
    request(client, @supported_api.close, params)
  end

  @doc """
  Query refund info.

  See: https://docs.open.alipay.com/api_1/alipay.trade.fastpay.refund.query

  ## Examples:

      ExAlipay.Client.refund_query(client, %{
        out_trade_no: "out_trade_no",
        out_request_no: "out_request_no",
      })
  """
  def refund_query(client, params) do
    request(client, @supported_api.refund_query, params)
  end

  @doc """
  Fetch bill download url.

  See: https://docs.open.alipay.com/api_15/alipay.data.dataservice.bill.downloadurl.query

  ## Examples:

      ExAlipay.Client.bill_downloadurl_query(client, %{
        bill_type: "trade",
        bill_date: "2019-06-06",
      })
  """
  def bill_downloadurl_query(client, params) do
    request(client, @supported_api.bill_downloadurl_query, params)
  end

  @doc """
  Get user auth_token by auth_code.

  See: https://docs.open.alipay.com/api_9/alipay.system.oauth.token

  ## Examples:

      ExAlipay.Client.auth_token(client, %{
        grant_type: "authorization_code",
        code: "an auth_code",
      })
  """
  def auth_token(client, params) do
    request(client, @supported_api.auth_token, nil, params)
  end

  @doc """
  Get user info by auth_token.

  See: https://docs.open.alipay.com/api_2/alipay.user.info.share

  ## Examples:

      ExAlipay.Client.user_info(client, %{
        auth_token: "an auth_token",
      })
  """
  def user_info(client, params) do
    request(client, @supported_api.user_info, nil, params)
  end

  @doc """
  Transfer money to users' alipay acoount.

  See: https://docs.open.alipay.com/api_28/alipay.fund.trans.toaccount.transfer

  ## Examples:

      ExAlipay.Client.transfer(client, %{
        payee_account: "an alipay account",
        out_biz_no: "an out_biz_no",
        amount: 100,
        payee_type: "ALIPAY_LOGONID",
      })
  """
  def transfer(client, params) do
    request(client, @supported_api.transfer, params)
  end

  @doc """
  Query transfer order.

  See: https://docs.open.alipay.com/api_28/alipay.fund.trans.order.query

  ## Examples:

      ExAlipay.Client.transfer_query(client, %{
        out_biz_no: "an out_biz_no",
      })
  """
  def transfer_query(client, params) do
    request(client, @supported_api.transfer_query, params)
  end

  @doc """
  Get auth url for alipay web auth.

  See: https://docs.open.alipay.com/289/105656

  ## Examples:

      ExAlipay.Client.auth_url(client, %{
        redirect_uri: http://example.com/auth_redirect_url,
        scope: "auth_user",
        state: "state"
      })
  """
  def auth_url(client, %{redirect_uri: redirect_uri} = params) do
    base_url = get_base_auth_url(client)
    state = Map.get(params, :state)
    scope = Map.get(params, :scope, "auth_user")
    url = "#{base_url}?app_id=#{client.appid}&scope=#{scope}&redirect_uri=#{redirect_uri}"

    case state do
      nil -> url
      _ -> "#{url}&state=#{state}"
    end
  end

  @doc """
  Get auth string for alipay app auth.

  See: https://docs.open.alipay.com/218/105327/

  ## Examples:

      ExAlipay.Client.app_auth_str(client, %{
        target_id: "target_id"
      })
  """
  def app_auth_str(client, %{target_id: target_id}) do
    params = %{
      apiname: "com.alipay.account.auth",
      method: "alipay.open.auth.sdk.code.get",
      app_id: client.appid,
      app_name: "mc",
      biz_type: "openservice",
      pid: client.pid,
      product_id: "APP_FAST_LOGIN",
      scope: "kuaijie",
      target_id: target_id,
      auth_type: "AUTHACCOUNT",
      sign_type: "RSA2"
    }

    data = Utils.create_sign_str(params)
    sign = Utils.create_sign(client, data)
    "#{data}&sign=#{sign}"
  end

  @doc """
  Perform the request to alipay backend.
  """
  @spec request(%Client{}, binary, map, map) :: map
  def request(client, method, content, ext_params \\ %{}) do
    url = Utils.build_request_url(client, method, content, ext_params)

    with {:ok, resp} <- @http_adapter.get(url),
         {:ok, body} <- verify_status(resp),
         {:ok, key} <- verify_request_sign(client, body),
         {:ok, json_data} <- Jason.decode(body),
         {:ok, resp_data} <- check_response_data(json_data[key]) do
      resp_data
    else
      {:error, error} -> raise error
    end
  end

  defp verify_status(%{status_code: 200, body: body}) do
    {:ok, body}
  end

  defp verify_status(%{status_code: status_code}) do
    {:error, %RequestError{status_code: status_code}}
  end

  defp check_response_data(resp_data) do
    case resp_data["code"] do
      # api response like auth_token without code
      nil -> {:ok, resp_data}
      # 10000 is the success code of alipay
      "10000" -> {:ok, resp_data}
      _ -> {:error, ResponseError.from_map(resp_data)}
    end
  end

  defp verify_request_sign(client, body) do
    regex = ~r/"(?<key>\w+_response)":(?<response>{[^}]+})/

    case Regex.named_captures(regex, body) do
      %{"response" => response, "key" => key} ->
        resp_json = Jason.decode!(body)
        ok? = RSA.verify(response, client.sign_type, client.public_key, resp_json["sign"])

        cond do
          ok? -> {:ok, key}
          not ok? -> {:error, %RequestError{reason: "verify sign failed"}}
        end

      nil ->
        {:error, %RequestError{reason: "unexpected response data"}}
    end
  end

  @doc """
  Verify the sign of alipay notify, used in handler of notify_url.
  """
  @spec verify_notify_sign?(Client.t(), Map.t()) :: boolean
  def verify_notify_sign?(client, body) do
    {sign, body} = Map.pop(body, :sign)
    {sign_type, body} = Map.pop(body, :sign_type)

    body
    |> Utils.create_sign_str()
    |> RSA.verify(sign_type, client.public_key, sign)
  end

  defp get_base_auth_url(%Client{sandbox?: false}) do
    "https://openauth.alipay.com/oauth2/publicAppAuthorize.htm"
  end

  defp get_base_auth_url(%Client{sandbox?: true}) do
    "https://openauth.alipaydev.com/oauth2/publicAppAuthorize.htm"
  end
end
