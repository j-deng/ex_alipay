defmodule ExAlipayRSATest do
  use ExUnit.Case
  alias ExAlipay.RSA
  doctest ExAlipay

  @public_key ~s(-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQAB\n-----END PUBLIC KEY-----)
  @private_key ~s(-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQCfq836Ik1FTMdzLF8PwHuUZhkfSikepLOXCBGXs+dNHq7+jBK58veZjTGlDQFF5x06O28Cf0n2DkalGoOw6zDzTyUBzGmdH3n89uh7imFDATxZjDSMVLkdEVivpFePuyBnl78udqrLHG+Tjgqts1/DPAFbDdIwVQy+xrSnVvLJ/QIDAQABAoGAPi7XmemP9EQxjM4j+2t39VRJxmDIYNG9yzzuNQlwNB2WAzYj+N0BxoAxbFkDPOkD/fC1i+BsunHW22fXD6iYuBomuO8DERatA1Hp36/jLoJLnfxQw/w/ToC68i8wuOMe0iyVUNrV+T/ecYMvYLTtEzw8jB4NfvaBpZnUEy261XUCQQDm2CZYwRnmP9diMh7mKQHdCTUQ5crWyqImy8F0Y10gMO4j/kchWqR+746GapwutJnt7MnwJr4lO5E7Y5W3HI2zAkEAsRIjyDFIcHZWf6/qnvSJbI5fxUrr2WTMa8ZS6z+Ik0ueXoE1KnS1v1CabD+/8ynCsXixycVvHhZx9xqntS5RjwJADm1z+BgZhkp3K6v2QmxNsYLhziyOgN4pREN3085iA6ELQTSjPXJs1YIjZkNDf6fJ9xTViizhtXIDobKXqNogAQJAKOwSTO/m1+bhcr0LMhU9tVLqG0SHYUSEYdwBydBzFeeCAEFIMjmqzz4nkiDhkabzEeTc4c65MXDqgbstSxgbTQJBALkt3Xjun50XUDFY4YIVIj8c3Zi74HpXl667lzstf2sk8hwB7SLg3zT53o2RUjam4jk1GjFp8B68xT5B5WY2jOM=\n-----END RSA PRIVATE KEY-----)

  test "rsa sign and verify RSA and RSA2" do
    str = "yoyoyo"

    ["RSA", "RSA2"]
    |> Enum.map(fn sign_type ->
      signature = RSA.sign(str, sign_type, @private_key)
      assert is_binary(signature) and byte_size(signature) > 0
      assert RSA.verify(str, sign_type, @public_key, signature)
    end)
  end

  test "rsa verify returns false" do
    str = "yoyoyo"
    sign_type = "RSA"
    signature = "error signature"
    assert false == RSA.verify(str, sign_type, @public_key, signature)
  end
end
