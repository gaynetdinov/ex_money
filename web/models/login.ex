defmodule ExMoney.Login do
  use ExMoney.Web, :model

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
    field :last_fail_at, Ecto.DateTime
    field :last_fail_message, :string
    field :last_fail_error_class, :string
    field :last_request_at, Ecto.DateTime
    field :last_success_at, Ecto.DateTime
    field :status, :string
    field :country_code, :string
    field :interactive_html, :string
    field :interactive_fields_names, {:array, :string}
    field :stage, :string
    field :store_credentials, :boolean, default: false

    belongs_to :user, ExMoney.User

    timestamps
  end

  def success_callback_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(saltedge_login_id), ~w())
  end

  def failure_callback_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(saltedge_login_id last_fail_error_class last_fail_message), ~w())
  end

  def notify_callback_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(stage), ~w())
  end

  #@required_fields ~w(
  #  secret
  #  finished
  #  finished_recent
  #  partial
  #  automatic_fetch
  #  interactive
  #  provider_score
  #  provider_name
  #  last_fail_at
  #  last_fail_message
  #  last_fail_error_class
  #  last_request_at
  #  last_success_at
  #  status
  #  country_code
  #  interactive_html
  #  interactive_fields_names
  #  stage
  #  store_credentials
  #)

  #@optional_fields ~w()

  #def changeset(model, params \\ :empty) do
  #  model
  #  |> cast(params, @required_fields, @optional_fields)
  #end
end
