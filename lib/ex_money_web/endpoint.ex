defmodule ExMoney.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :ex_money

  socket "/refresh_socket", ExMoney.RefreshSocket,
    websocket: true, # Phoenix.Transports.WebSocket
    longpoll: true # Phoenix.Transports.LongPoll

  plug Plug.Static,
    at: "/", from: :ex_money, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_ex_money_key",
    signing_salt: "jxpF+oZR"

  plug ExMoney.Web.Router
end
