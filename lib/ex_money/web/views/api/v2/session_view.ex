defmodule ExMoney.Web.Api.V2.SessionView do
  use ExMoney.Web, :view

  def render("login.json", %{user: user, exp: exp, jwt: jwt}) do
    %{
      user_name: user.name,
      user_email: user.email,
      exp: exp,
      jwt: jwt
    }
  end

  def render("error.json", %{message: message}) do
    %{errors: [message]}
  end
end
