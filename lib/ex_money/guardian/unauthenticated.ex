defmodule ExMoney.Guardian.Unauthenticated do
  alias ExMoney.{Repo, User}

  import Ecto.Query

  def unauthenticated(conn, _params) do
    case Repo.one(from u in User, select: count(u.id)) do
      0 -> Phoenix.Controller.redirect(conn, to: "/setup/new")
      _ -> Phoenix.Controller.redirect(conn, to: "/login")
    end
  end
end
