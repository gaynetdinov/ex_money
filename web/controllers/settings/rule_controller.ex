defmodule ExMoney.Settings.RuleController do
  use ExMoney.Web, :controller
  alias ExMoney.{Repo, Rule, Account, Category}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  plug :scrub_params, "rule" when action in [:create, :update]

  def index(conn, _params) do
    rules = Repo.all(from r in Rule, preload: [:account])

    render(conn, :index,
      rules: rules,
      topbar: "settings",
      navigation: "rules"
    )
  end

  def new(conn, params) do
    target = case params["type"] do
      nil -> []
      "assign_category" -> Repo.all(Category.select_list)
      "withdraw_to_cash" -> Repo.all(Account.only_custom)
    end

    accounts = Account.only_saltedge |> Repo.all
    changeset = Rule.changeset(%Rule{})

    render(conn, :new,
      changeset: changeset,
      target: target,
      accounts: accounts,
      topbar: "settings",
      navigation: "rules"
    )
  end

  def create(conn, %{"rule" => rule_params}) do
    changeset = Rule.changeset(%Rule{}, rule_params)

    case Repo.insert(changeset) do
      {:ok, rule} ->
        apply_rule_for_all(rule_params["apply_for_all"], rule)

        conn
        |> put_flash(:info, "Rule created successfully.")
        |> redirect(to: settings_rule_path(conn, :index))
      {:error, changeset} ->
        accounts = Account.only_saltedge |> Repo.all
        render(conn, :new,
          changeset: changeset,
          accounts: accounts,
          topbar: "settings",
          navigation: "rules"
        )
    end
  end

  def show(conn, %{"id" => id}) do
    rule = Repo.get!(Rule, id)
    render(conn, :show,
      rule: rule,
      topbar: "settings",
      navigation: "rules"
    )
  end

  def edit(conn, %{"id" => id}) do
    rule = Repo.get!(Rule, id)

    target = case rule.type do
      nil -> []
      "assign_category" -> Repo.all(Category.select_list)
      "withdraw_to_cash" -> Repo.all(Account.only_custom)
    end
    accounts = Account.only_saltedge |> Repo.all
    changeset = Rule.changeset(rule)

    render(conn, :edit,
      rule: rule,
      changeset: changeset,
      target: target,
      accounts: accounts,
      topbar: "settings",
      navigation: "rules"
    )
  end

  def update(conn, %{"id" => id, "rule" => rule_params}) do
    rule = Repo.get!(Rule, id)
    changeset = Rule.changeset(rule, rule_params)

    case Repo.update(changeset) do
      {:ok, rule} ->
        apply_rule_for_all(rule_params["apply_for_all"], rule)

        conn
        |> put_flash(:info, "Rule updated successfully.")
        |> redirect(to: settings_rule_path(conn, :show, rule))
      {:error, changeset} ->
        render(conn, :edit,
          rule: rule,
          changeset: changeset,
          topbar: "settings",
          navigation: "rules"
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    rule = Repo.get!(Rule, id)

    Repo.delete!(rule)

    conn
    |> put_flash(:info, "Rule deleted successfully.")
    |> redirect(to: settings_rule_path(conn, :index))
  end

  defp apply_rule_for_all("false", _rule), do: :nothing
  defp apply_rule_for_all("true", rule) do
    GenServer.cast(:rule_processor, {:process_all, rule.id})
  end
end
