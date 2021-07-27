defmodule ExAlipay.RSA do
  @moduledoc """
  RSA sign and verify module for ExAlipay.
  """

  @spec sign(binary, atom, binary) :: binary
  def sign(str, sign_type, private_key) do
    [rsa_entry] = :public_key.pem_decode(private_key)
    key = :public_key.pem_entry_decode(rsa_entry)
    :public_key.sign(str, get_algo(sign_type), key) |> Base.encode64()
  end

  @spec verify(binary, atom, binary, binary) :: boolean
  def verify(str, sign_type, public_key, signature) do
    try do
      signature = Base.decode64!(signature)
      [rsa_entry] = :public_key.pem_decode(public_key)
      key = :public_key.pem_entry_decode(rsa_entry)
      :public_key.verify(str, get_algo(sign_type), signature, key)
    rescue
      _ -> false
    end
  end

  @spec verify_in_cert_mode(any, any, binary, any) :: boolean
  def verify_in_cert_mode(str, sign_type, alipay_cert_publick_key, signature) do
    with signature <- Base.decode64!(signature),
         {:ok, cert} <- X509.Certificate.from_pem(alipay_cert_publick_key),
         public_key <- X509.Certificate.public_key(cert) do
      :public_key.verify(str, get_algo(sign_type), signature, public_key)
    else
      _ -> false
    end
  end

  @spec app_cert_sn(ExAlipay.Client.t()) :: binary
  def app_cert_sn(%ExAlipay.Client{app_cert: cert}), do: cert_sn(cert)

  @spec alipay_root_cert_sn(ExAlipay.Client.t()) :: binary
  def alipay_root_cert_sn(%ExAlipay.Client{alipay_root_cert: cert}), do: cert_sn(cert)

  @doc """
    generate certificate sn by alipay way
  """
  @spec cert_sn(bitstring()) :: bitstring()
  def cert_sn(cert_content) when is_bitstring(cert_content) do
    X509.from_pem(cert_content)
    |> Enum.filter(fn cert ->
      match?({:Certificate, _, {:AlgorithmIdentifier, {1, 2, 840, 113_549, 1, 1, _}, _}, _}, cert)
    end)
    |> Enum.map(&cert_sn/1)
    |> Enum.join("_")
  end

  alias X509.RDNSequence, as: RNDS

  def cert_sn({:Certificate, _, _, _} = cert) do
    issuer = X509.Certificate.issuer(cert)
    [cn] = RNDS.get_attr(issuer, "CN")
    # maybe blank
    ou = RNDS.get_attr(issuer, "OU") |> List.first()
    [o] = RNDS.get_attr(issuer, "O")
    [c] = RNDS.get_attr(issuer, "C")
    serial = X509.Certificate.serial(cert)

    sn =
      if is_nil(ou),
        do: "CN=#{cn},O=#{o},C=#{c}#{serial}",
        else: "CN=#{cn},OU=#{ou},O=#{o},C=#{c}#{serial}"

    :crypto.hash(:md5, sn)
    |> Base.encode16(case: :lower)
  end

  defp get_algo(sign_type) do
    case sign_type do
      "RSA" -> :sha
      "RSA2" -> :sha256
      _ -> raise ArgumentError, "Unsupported sign_type: #{sign_type}"
    end
  end
end
