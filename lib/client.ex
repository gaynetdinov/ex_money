defmodule Saltedge do
  def get() do
    method = "GET"
    #url = "https://www.saltedge.com/api/v2/countries"
    #url = "https://www.saltedge.com/api/v2/client/info"
    #url = "https://www.saltedge.com/api/v2/providers/fakebank_simple_xf"
    #url = "https://www.saltedge.com/api/v2/customers"
    #url = "https://www.saltedge.com/api/v2/logins"
    url = "https://www.saltedge.com/api/v2/tokens/create"
    url = "https://www.saltedge.com/api/v2/accounts"

    client_id = ""
    service_secret = ""
    expires_at = timestamp + 60


    body = """
    {
      "data": {
        "customer_id": "",
        "fetch_type": "recent"
      }
    }
    """
    req = "#{expires_at}|#{method}|#{url}|"

    headers = [
      {"Accept", "application/json"},
      {"Content-type", "application/json"},
      {"Expires-at", expires_at},
      {"Signature", signature(req)},
      {"Client-id", client_id},
      {"Service-secret", service_secret}
    ]

    #HTTPoison.post(url, body, headers)
    HTTPoison.get(url, headers)
  end

  def signature(url) do
    :public_key.sign(url, :sha, read_private_key())
    |> Base.encode64
  end

  defp read_private_key() do
    File.read!("./lib/saltedge_private.pem")
    |> :public_key.pem_decode
    |> hd() |> :public_key.pem_entry_decode
  end

  defp timestamp() do
    {mgsec, sec, _mcs} = :os.timestamp

    mgsec * 1_000_000 + sec
  end
end
