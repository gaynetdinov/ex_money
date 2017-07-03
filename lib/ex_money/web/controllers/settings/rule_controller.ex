defmodule ExMoney.Web.Settings.RuleController do
  use ExMoney.Web, :controller
  alias ExMoney.{Repo, Rule, Account, Category}

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated

  plug :scrub_params, "rule" when action in [:create, :update]

  def index(conn, _params) do
    rules = Rule.with_account_ordered |> Repo.all

    map = Enum.reduce(rules, %{account_ids: [], category_ids: []}, fn(rule, acc) ->
      {_, acc} = case rule.type do
        "assign_category" -> Map.get_and_update(acc, :category_ids, fn(current) -> {current, [rule.target_id | current]} end)
        "withdraw_to_cash" -> Map.get_and_update(acc, :account_ids, fn(current) -> {current, [rule.target_id | current]} end)
      end

      acc
    end)

    categories = map.category_ids
    |> Category.by_ids
    |> Repo.all
    |> Enum.reduce(%{}, fn(c, acc) -> Map.put(acc, c.id, c) end)

    accounts = map.account_ids
    |> List.flatten
    |> Account.by_ids
    |> Repo.all
    |> Enum.reduce(%{}, fn(a, acc) -> Map.put(acc, a.id, a) end)

    render conn, :index,
      rules: rules,
      categories: categories,
      accounts: accounts,
      topbar: "settings",
      navigation: "rules"
  end

  def new(conn, params) do
    type = params["type"]
    target = build_target(type)
    accounts = Account.only_saltedge |> Repo.all
    changeset = Rule.changeset(%Rule{})

    render conn, :new,
      changeset: changeset,
      target: target,
      type: type,
      accounts: accounts,
      topbar: "settings",
      navigation: "rules"
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
        target = build_target(rule_params["type"])

        render conn, :new,
          changeset: changeset,
          accounts: accounts,
          type: rule_params["type"],
          target: target,
          topbar: "settings",
          navigation: "rules"
    end
  end

  def show(conn, %{"id" => id}) do
    rule = Repo.get!(Rule, id)
    render conn, :show,
      rule: rule,
      topbar: "settings",
      navigation: "rules"
  end

  def edit(conn, %{"id" => id} = params) do
    rule = Repo.get!(Rule, id)

    type = params["type"]
    target = build_target(type)
    accounts = Account.only_saltedge |> Repo.all
    changeset = Rule.changeset(rule)

    render conn, :edit,
      rule: rule,
      changeset: changeset,
      target: target,
      type: type,
      accounts: accounts,
      topbar: "settings",
      navigation: "rules"
  end

  def update(conn, %{"id" => id, "rule" => rule_params}) do
    rule = Repo.get!(Rule, id)
    type = rule_params["type"]
    target = build_target(type)
    changeset = Rule.changeset(rule, rule_params)

    case Repo.update(changeset) do
      {:ok, rule} ->
        apply_rule_for_all(rule_params["apply_for_all"], rule)

        conn
        |> put_flash(:info, "Rule updated successfully.")
        |> redirect(to: settings_rule_path(conn, :index))
      {:error, changeset} ->
        accounts = Account.only_saltedge |> Repo.all
        render conn, :edit,
          rule: rule,
          type: type,
          accounts: accounts,
          changeset: changeset,
          target: target,
          topbar: "settings",
          navigation: "rules"
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

  defp build_target(type) do
    case type do
      nil -> []
      "assign_category" ->
        categories = Repo.all(Category)

        Enum.reduce(categories, %{}, fn(category, acc) ->
          if is_nil(category.parent_id) do
            sub_categories = Enum.filter(categories, fn(c) -> c.parent_id == category.id end)
            |> Enum.map(fn(sub_category) -> {sub_category.humanized_name, sub_category.id} end)
            Map.put(acc, {category.humanized_name, category.id}, sub_categories)
          else
            acc
          end
        end)
      "withdraw_to_cash" -> Repo.all(Account.only_custom)
    end
  end
end
