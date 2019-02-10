defmodule ExMoney.RefreshSocket do
  use Phoenix.Socket
  use Guardian.Phoenix.Socket

  ## Channels
  channel "login_refresh:*", ExMoney.InteractiveChannel

  # Guardian handles authentication.
  def connect(_params, _socket), do: :error

  def id(_socket), do: nil
end
