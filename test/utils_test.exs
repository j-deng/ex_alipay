defmodule ExAlipayUtilsTest do
  use ExUnit.Case
  doctest ExAlipay

  alias ExAlipay.Utils

  defmodule AlipayClient do
    use ExAlipay.Client,
      appid: "2019111111",
      pid: "2019121212",
      public_key: ~s(-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQAB\n-----END PUBLIC KEY-----),
      private_key: ~s(-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQABAoGAPi7XmemP9EQxjM4j+2t39VRJxmDIYNG9yzzuNQlwNB2WAzYj+N0BxoAxbFkDPOkD/fC1i+BsunHW22fXD6iYuBomuO8DERatA1Hp36/jLoJLnfxQw/w/ToC68i8wuOMe0iyVUNrV+T/ecYMvYLTtEzw8jB4NfvaBpZnUEy261XUCQQDm2CZYwRnmP9diMh7mKQHdCTUQ5crWyqImy8F0Y10gMO4j/kchWqR+746GapwutJnt7MnwJr4lO5E7Y5W3HI2zAkEAsRIjyDFIcHZWf6/qnvSJbI5fxUrr2WTMa8ZS6z+Ik0ueXoE1KnS1v1CabD+/8ynCsXixycVvHhZx9xqntS5RjwJADm1z+BgZhkp3K6v2QmxNsYLhziyOgN4pREN3085iA6ELQTSjPXJs1YIjZkNDf6fJ9xTViizhtXIDobKXqNogAQJAKOwSTO/m1+bhcr0LMhU9tVLqG0SHYUSEYdwBydBzFeeCAEFIMjmqzz4nkiDhkabzEeTc4c65MXDqgbstSxgbTQJBALkt3Xjun50XUDFY4YIVIj8c3Zi74HpXl667lzstf2sk8hwB7SLg3zT53o2RUjam4jk1GjFp8B68xT5B5WY2jOM=\n-----END RSA PRIVATE KEY-----),
      sandbox?: true

    def client, do: @client
  end

  test "create sign" do
    params = %{b: "b", a: "a"}
    sign_str = Utils.create_sign_str(params)
    assert sign_str == "a=a&b=b"
    client = AlipayClient.client()
    assert Utils.create_sign(client, params) == Utils.create_sign(client, sign_str)
  end

  test "create request" do
    content = %{b: "b", a: "a"}
    client = AlipayClient.client()
    request_str = Utils.build_request_str(client, :page_pay, content, %{})
    request_url = Utils.build_request_url(client, :page_pay, content, %{})
    gate_way = Utils.get_gateway(client)
    assert String.starts_with?(request_url, gate_way)
    assert not String.starts_with?(request_str, gate_way)
    params = URI.decode_query(request_str)
    %{
      "app_id" => "2019111111",
      "biz_content" => _biz_content,
      "charset" => "utf-8",
      "format" => "JSON",
      "method" => "page_pay",
      "sign" => sign,
      "sign_type" => "RSA2",
      "timestamp" => _timestamp,
      "version" => "1.0"
    } = params
    {^sign, params} = Map.pop(params, "sign")
    assert sign == Utils.create_sign(client, params)
  end
end
