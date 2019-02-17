defmodule ExMoney.Web.Plugs.VerifySaltedgeSignature do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, opts) do
    Logger.info("Verified signature? => #{inspect signature(conn, opts[:callback])}")

    conn
  end

  defp signature(conn, callback) do
    case get_req_header(conn, "signature") do
      [] ->
        conn
      [saltedge_signature] ->
        msg = "https://ex-money.herokuapp.com/callbacks/#{callback}|#{conn.assigns.raw_body}"
        :public_key.verify(msg, :sha256, Base.decode64!(saltedge_signature), read_saltedge_public_key())
    end
  end

  defp read_saltedge_public_key do
    saltedge_public_key()
    |> :public_key.pem_decode()
    |> hd()
    |> :public_key.pem_entry_decode()
  end

  defp saltedge_public_key do
    System.get_env("SALTEDGE_PUBLIC_KEY") || File.read!(saltedge_public_key_path())
  end

  defp saltedge_public_key_path do
    Application.get_env(:ex_money, :saltedge)[:saltedge_public_key_path]
  end
end
