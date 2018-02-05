defmodule ExMoney.Login do
  use ExMoney.Web, :model

  alias ExMoney.Login

  schema "logins" do
    field :secret, :string
    field :saltedge_login_id, :integer
    field :finished, :boolean, default: false
    field :finished_recent, :boolean, default: false
    field :partial, :boolean, default: false
    field :automatic_fetch, :boolean, default: false
    field :interactive, :boolean, default: false
    field :provider_score, :string
    field :provider_name, :string
    field :last_fail_at, :naive_datetime
    field :last_fail_message, :string
    field :last_fail_error_class, :string
    field :last_request_at, :naive_datetime
    field :last_success_at, :naive_datetime
    field :status, :string
    field :country_code, :string
    field :interactive_html, :string
    field :interactive_fields_names, {:array, :string}
    field :stage, :string
    field :store_credentials, :boolean, default: false
    field :last_refreshed_at, :naive_datetime

    field :fetch_all_tried, :boolean, default: false

    belongs_to :user, ExMoney.User
    has_many :accounts, ExMoney.Account,
      on_delete: :delete_all,
      references: :saltedge_login_id,
      foreign_key: :saltedge_login_id

    timestamps()
  end

  def background_refresh do
    from l in Login,
      where: l.automatic_fetch == true,
      where: l.interactive == false
  end

  def by_user_id(user_id) do
    from l in Login, where: l.user_id == ^user_id
  end

  def by_user_and_saltedge_login(user_id, saltedge_login_id) do
    from l in Login,
      where: l.user_id == ^user_id,
      where: l.saltedge_login_id == ^saltedge_login_id,
      limit: 1
  end

  def by_saltedge_login_id(saltedge_login_id) do
    from l in Login,
      where: l.saltedge_login_id == ^saltedge_login_id,
      limit: 1
  end

  def success_callback_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(saltedge_login_id user_id)a)
    |> validate_required(~w(saltedge_login_id user_id)a)
    |> unique_constraint(:saltedge_login_id)
  end

  def failure_callback_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(saltedge_login_id last_fail_error_class last_fail_message)a)
    |> validate_required(:saltedge_login_id)
  end

  def notify_callback_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(stage)a)
    |> validate_required(:stage)
  end

  def interactive_callback_changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(stage interactive_fields_names interactive_html)a)
    |> validate_required(~w(stage interactive_fields_names)a)
  end

  @required_fields ~w(
    saltedge_login_id
    secret
    finished
    finished_recent
    partial
    automatic_fetch
    interactive
    provider_name
    status
    country_code
    stage
    store_credentials
    user_id
  )a

  @optional_fields ~w(
    interactive_fields_names
    interactive_html
    provider_score
    last_fail_at
    last_fail_message
    last_fail_error_class
    last_request_at
    last_success_at
  )a

  @update_fields ~w(
    finished
    finished_recent
    partial
    automatic_fetch
    interactive
    provider_name
    status
    country_code
    stage
    store_credentials
    interactive_fields_names
    interactive_html
    provider_score
    last_fail_at
    last_fail_message
    last_fail_error_class
    last_request_at
    last_success_at
    last_refreshed_at
    fetch_all_tried
  )a

  def create_changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def update_changeset(model, params \\ %{}) do
    model
    |> cast(params, @update_fields)
  end
end
