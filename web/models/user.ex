defmodule ExMoney.User do
  use ExMoney.Web, :model

  alias ExMoney.User

  schema "users" do
    field :name, :string
    field :email, :string
    field :encrypted_password, :string
    field :saltedge_customer_id, :string
    field :saltedge_token, :string
    field :password, :string, virtual: true
    field :last_login_at, Ecto.DateTime

    has_many :logins, ExMoney.Login
    has_many :accounts, ExMoney.Account

    timestamps
  end

  def by_email(email) do
    from u in User, where: u.email == ^email
  end

  def by_id(id) when is_integer(id) do
    from u in User,
      where: u.id == ^id,
      limit: 1
  end

  def by_id(customer_id) when is_binary(customer_id) do
    from u in User,
      where: u.saltedge_customer_id == ^customer_id,
      limit: 1
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(email password), ~w(name saltedge_customer_id))
    |> maybe_update_password
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(), ~w(name email password saltedge_customer_id last_login_at))
    |> maybe_update_password
  end

  def login_changeset(model), do: model |> cast(%{}, ~w(), ~w(email password))

  def login_changeset(model, params) do
    model
    |> cast(params, ~w(email password), ~w())
    |> validate_password
  end

  defp maybe_update_password(changeset) do
    case Ecto.Changeset.fetch_change(changeset, :password) do
      {:ok, password} ->
        changeset
        |> Ecto.Changeset.put_change(:encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
      :error -> changeset
    end
  end

  def valid_password?(nil, _), do: false
  def valid_password?(_, nil), do: false
  def valid_password?(password, crypted), do: Comeonin.Bcrypt.checkpw(password, crypted)

  defp validate_password(changeset) do
    case Ecto.Changeset.get_field(changeset, :encrypted_password) do
      nil -> password_incorrect_error(changeset)
      crypted -> validate_password(changeset, crypted)
    end
  end

  defp validate_password(changeset, crypted) do
    password = Ecto.Changeset.get_change(changeset, :password)
    if valid_password?(password, crypted), do: changeset, else: password_incorrect_error(changeset)
  end

  defp password_incorrect_error(changeset), do: Ecto.Changeset.add_error(changeset, :password, "is incorrect")
end
