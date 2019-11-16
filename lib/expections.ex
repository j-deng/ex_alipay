defmodule ExAlipay.RequestError do
  @type t :: %__MODULE__{status_code: number, reason: any}

  defexception status_code: 200, reason: nil

  def message(%__MODULE__{status_code: status_code, reason: nil}) do
    "ExAlipay request failed with status_code #{status_code}"
  end

  def message(%__MODULE__{status_code: 200, reason: reason}) do
    "ExAlipay request failed, #{inspect(reason)}"
  end
end

defmodule ExAlipay.ResponseError do
  @type t :: %__MODULE__{
          code: binary,
          sub_code: binary,
          msg: binary,
          sub_msg: binary
        }

  defexception [:code, :sub_code, :msg, :sub_msg]

  def message(%__MODULE__{sub_code: sub_code, sub_msg: sub_msg}) do
    "ExAlipay response failed with code #{sub_code} - #{sub_msg}"
  end

  def from_map(%{"code" => code, "sub_code" => sub_code, "msg" => msg, "sub_msg" => sub_msg}) do
    %__MODULE__{
      code: code,
      sub_code: sub_code,
      msg: msg,
      sub_msg: sub_msg
    }
  end
end
