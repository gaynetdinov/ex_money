defmodule Mix.Tasks.ExMoney.PurgeTokens do
  use Mix.Task

  @shortdoc "Purges stale Guardian tokens from a database"

  def run(_args) do
    {:ok, pid} = ExMoney.Repo.start_link

    GuardianDb.Token.purge_expired_tokens!

    ExMoney.Repo.stop(pid)
  end
end
