# ExAlipay

![CI](https://travis-ci.org/j-deng/ex_alipay.svg?branch=master)

An Alipay client that is extendable.

The docs can be found at [https://hexdocs.pm/ex_alipay/0.1.0](https://hexdocs.pm/ex_alipay/0.1.0).

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

## Installation

```elixir
def deps do
  [
    {:ex_alipay, "~> 0.1.0"}
  ]
end
```

### Example Usage:

Define a module `AlipayClient` that use `ExAlipay.Client`,
`AlipayClient` module will have new defined functions that calling
the same `ExAlipay.Client` functions, the difference is that it stores
the client with module property `@client` for convenient uasge:

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
  # response a plain text `success` tio alipay
else
  # response with error
end
```

Extend new api you need that not in `ExAlipay.Client`.

```elixir
defmodule AlipayClient do
  use ExAlipay.Client, Application.fetch_env!(:my_app, __MODULE__)

  # access the public api `request` that defined in `ExAlipay.Client`
  # also possible to use functions in `ExAlipay.Utils` directly
  # see: https://docs.open.alipay.com/api_1/alipay.trade.precreate
  def pre_create(params), do: request(@client, "alipay.trade.precreate", params)
end

# now we can use the new api
# AlipayClient.pre_create(%{})
```
