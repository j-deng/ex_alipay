defmodule ExAlipay.RSA do
  @moduledoc """
  RSA sign and verify module for ExAlipay.
  """

  @spec sign(binary, atom, binary) :: binary
  def sign(str, sign_type, private_key) do
    [rsa_entry] = :public_key.pem_decode(private_key)
    key = :public_key.pem_entry_decode(rsa_entry)
    :public_key.sign(str, get_alg(sign_type), key) |> Base.encode64
  end

  @spec verify(binary, atom, binary, binary) :: boolean
  def verify(str, sign_type, public_key, signature) do
    try do
      signature = Base.decode64!(signature)
      [rsa_entry] = :public_key.pem_decode(public_key)
      key = :public_key.pem_entry_decode(rsa_entry)
      :public_key.verify(str, get_alg(sign_type), signature, key)
    rescue
      _ -> false
    end
  end

  defp get_alg(sign_type) do
    case sign_type do
      "RSA" -> :sha
      "RSA2" -> :sha256
      _ -> raise ArgumentError, "Unsupported sign_type: #{sign_type}"
    end
  end
end
