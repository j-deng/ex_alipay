defmodule ExAlipayClientTest do
  use ExUnit.Case
  doctest ExAlipay

  alias ExAlipay.RSA
  import Mox

  @private_key ~s(-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQABAoGAPi7XmemP9EQxjM4j+2t39VRJxmDIYNG9yzzuNQlwNB2WAzYj+N0BxoAxbFkDPOkD/fC1i+BsunHW22fXD6iYuBomuO8DERatA1Hp36/jLoJLnfxQw/w/ToC68i8wuOMe0iyVUNrV+T/ecYMvYLTtEzw8jB4NfvaBpZnUEy261XUCQQDm2CZYwRnmP9diMh7mKQHdCTUQ5crWyqImy8F0Y10gMO4j/kchWqR+746GapwutJnt7MnwJr4lO5E7Y5W3HI2zAkEAsRIjyDFIcHZWf6/qnvSJbI5fxUrr2WTMa8ZS6z+Ik0ueXoE1KnS1v1CabD+/8ynCsXixycVvHhZx9xqntS5RjwJADm1z+BgZhkp3K6v2QmxNsYLhziyOgN4pREN3085iA6ELQTSjPXJs1YIjZkNDf6fJ9xTViizhtXIDobKXqNogAQJAKOwSTO/m1+bhcr0LMhU9tVLqG0SHYUSEYdwBydBzFeeCAEFIMjmqzz4nkiDhkabzEeTc4c65MXDqgbstSxgbTQJBALkt3Xjun50XUDFY4YIVIj8c3Zi74HpXl667lzstf2sk8hwB7SLg3zT53o2RUjam4jk1GjFp8B68xT5B5WY2jOM=\n-----END RSA PRIVATE KEY-----)

  defmodule AlipayClient do
    use ExAlipay.Client,
      appid: "2019111111",
      pid: "2019121212",
      public_key: ~s(-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQAB\n-----END PUBLIC KEY-----),
      private_key: ~s(-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQABAoGAPi7XmemP9EQxjM4j+2t39VRJxmDIYNG9yzzuNQlwNB2WAzYj+N0BxoAxbFkDPOkD/fC1i+BsunHW22fXD6iYuBomuO8DERatA1Hp36/jLoJLnfxQw/w/ToC68i8wuOMe0iyVUNrV+T/ecYMvYLTtEzw8jB4NfvaBpZnUEy261XUCQQDm2CZYwRnmP9diMh7mKQHdCTUQ5crWyqImy8F0Y10gMO4j/kchWqR+746GapwutJnt7MnwJr4lO5E7Y5W3HI2zAkEAsRIjyDFIcHZWf6/qnvSJbI5fxUrr2WTMa8ZS6z+Ik0ueXoE1KnS1v1CabD+/8ynCsXixycVvHhZx9xqntS5RjwJADm1z+BgZhkp3K6v2QmxNsYLhziyOgN4pREN3085iA6ELQTSjPXJs1YIjZkNDf6fJ9xTViizhtXIDobKXqNogAQJAKOwSTO/m1+bhcr0LMhU9tVLqG0SHYUSEYdwBydBzFeeCAEFIMjmqzz4nkiDhkabzEeTc4c65MXDqgbstSxgbTQJBALkt3Xjun50XUDFY4YIVIj8c3Zi74HpXl667lzstf2sk8hwB7SLg3zT53o2RUjam4jk1GjFp8B68xT5B5WY2jOM=\n-----END RSA PRIVATE KEY-----),
      sandbox?: true

    def pre_create(params), do: request(@client, "alipay.trade.precreate", params)
  end

  defp get_response(status_code \\ 200, data \\ %{test: "test"}) do
    response = Jason.encode!(data)
    signature = RSA.sign(response, "RSA2", @private_key)
    body = ~s({"trade_response":#{response},"sign":"#{signature}"})
    {:ok, %{status_code: status_code, body: body}}
  end

  test "payment create" do
    params = %{
      out_trade_no: "an out_trade_no",
      total_amount: 100,
      subject: "the subject",
      return_url: "http://example.com/return_url",
      notify_url: "http://example.com/notify_url",
    }
    assert AlipayClient.page_pay(params)
    assert AlipayClient.wap_pay(params)
    assert AlipayClient.app_pay(params)
    assert false == AlipayClient.verify_notify_sign?(%{})
  end

  test "exist api with success status" do
    params = %{
      out_trade_no: "out_trade_no",
    }
    expect(ExAlipay.HttpMock, :get, fn _ -> get_response() end)
    assert %{"test" => "test"} == AlipayClient.query(params)
  end

  test "invalid sign" do
    params = %{}
    body = ~s({"trade_response":{"test":"test"},"sign":"invalid signature"})
    response = {:ok, %{status_code: 200, body: body}}
    expect(ExAlipay.HttpMock, :get, fn _ -> response end)
    assert_raise ExAlipay.RequestError, fn -> AlipayClient.query(params) end
  end

  test "invalid status_code" do
    params = %{}
    {:ok, %{status_code: 200, body: body}} = get_response()
    response = {:ok, %{status_code: 400, body: body}}
    expect(ExAlipay.HttpMock, :get, fn _ -> response end)
    assert_raise ExAlipay.RequestError, fn -> AlipayClient.query(params) end
  end

  test "invalid response code" do
    params = %{}
    data = %{
      "code" => "40000",
      "sub_code" => "YOYOYO",
      "msg" => "YOYOYO",
      "sub_msg" => "YOYOYO",
    }
    response = get_response(200, data)
    expect(ExAlipay.HttpMock, :get, fn _ -> response end)
    assert_raise ExAlipay.ResponseError, fn -> AlipayClient.query(params) end
  end

  test "extend new api method" do
    # suppose with an empty params
    params = %{}
    expect(ExAlipay.HttpMock, :get, fn _ -> get_response() end)
    assert %{"test" => "test"} == AlipayClient.pre_create(params)
  end
end
