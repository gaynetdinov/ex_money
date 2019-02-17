defmodule ExMoney.Saltedge.Client do
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
    app_id = Application.get_env(:ex_money, :saltedge_app_id)
    secret = Application.get_env(:ex_money, :saltedge_secret)

    url = base_url() <> "/" <> endpoint
    str_method = to_string(method) |> String.upcase
    request = "#{expires_at()}|#{str_method}|#{url}|#{body}"

    headers = [
      {"Accept", "application/json"},
      {"Content-type", "application/json"},
      {"Expires-at", expires_at()},
      {"Signature", signature(request)},
      {"App-id", app_id},
      {"Secret", secret}
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
    :public_key.sign(url, :sha256, read_private_key())
    |> Base.encode64
  end

  defp read_private_key do
    private_key()
    |> :public_key.pem_decode
    |> hd() |> :public_key.pem_entry_decode
  end

  defp private_key() do
    System.get_env("SALTEDGE_KEY") || File.read!(private_key_path())
  end

  defp private_key_path() do
    Application.get_env(:ex_money, :saltedge)[:private_key_path]
  end

  defp expires_at do
    {mgsec, sec, _mcs} = :os.timestamp

    mgsec * 1_000_000 + sec + 60
  end

  defp base_url() do
    Application.get_env(:ex_money, :saltedge)[:base_url]
  end
end
