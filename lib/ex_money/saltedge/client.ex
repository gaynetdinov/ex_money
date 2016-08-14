defmodule ExMoney.Saltedge.Client do
  @base_url "https://www.saltedge.com/api/v3/"

  @doc """
  A client for Saltedge API

  ## Examples

  ### To get list of countries

  iex> ExMoney.SaltedgeClient.request(:get, "countries")

  %{"data" => ["AD", "AE", "AM", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE",
   "BG", "BH", "BJ", "BM", "BN", "BO", "BR", "BS", "BY", "BZ", "CA", "CH", "CL",
   "CM", "CN", "CO", "CR", "CY", "CZ", "DE", "DK", "DM", "DO", "EC", "EE", "EG",
   "ES", "ET", "FI", "FM", "FR", "GB", "GE", "GR", "HK", "HN", "HR", "HT", "HU",
   ...]}

  ### To obtain a fake login

  body =
    {
      "data": {
        "customer_id": "",
        "country_code": "XF",
        "provider_code": "fakebank_simple_xf",
        "fetch_type": "recent",
        "credentials": {
          "login": "username",
          "password": "secret"
        }
      }
    }

  iex> ExMoney.SaltedgeClient.request(:post, "logins", body)
  """
  def request(method, endpoint, body \\ "") do
    client_id = Application.get_env(:ex_money, :saltedge_client_id)
    service_secret = Application.get_env(:ex_money, :saltedge_service_secret)

    url = @base_url <> endpoint
    str_method = to_string(method) |> String.upcase
    request = "#{expires_at}|#{str_method}|#{url}|#{body}"

    headers = [
      {"Accept", "application/json"},
      {"Content-type", "application/json"},
      {"Expires-at", expires_at},
      {"Signature", signature(request)},
      {"Client-id", client_id},
      {"Service-secret", service_secret}
    ]

    case HTTPoison.request(method, url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{body: body}} ->
        {:error, Poison.decode!(body)}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def signature(url) do
    :public_key.sign(url, :sha, read_private_key())
    |> Base.encode64
  end

  defp read_private_key do
    private_key
    |> :public_key.pem_decode
    |> hd() |> :public_key.pem_entry_decode
  end

  defp private_key do
    System.get_env("SALTEDGE_KEY") || File.read!("./lib/saltedge_private.pem")
  end

  defp expires_at do
    {mgsec, sec, _mcs} = :os.timestamp

    mgsec * 1_000_000 + sec + 60
  end
end
