defmodule ExMoney.Guardian.Serializer do
  @behaviour Guardian.Serializer

  alias ExMoney.{Repo, User}

  def for_token(user = %User{}), do: { :ok, "User:#{user.id}" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("User:" <> id), do: { :ok, Repo.get(User, String.to_integer(id)) }
  def from_token(_thing), do: { :error, "Unknown resource type" }
end
