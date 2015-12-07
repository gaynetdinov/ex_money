defmodule ExMoney.User do
  use ExMoney.Web, :model

  schema "users" do
    field :name, :string
    field :email, :string
    field :encrypted_password, :string
    field :saltedge_customer_id, :string
    field :saltedge_token, :string
    field :password, :string, virtual: true

    has_many :logins, ExMoney.Login

    timestamps
  end

  def by_email(email) do
    from u in ExMoney.User, where: u.email == ^email
  end

  def by_customer_id(customer_id) do
    from u in ExMoney.User, where: u.saltedge_customer_id == ^to_string(customer_id)
  end

  def create_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(name email password), ~w(saltedge_customer_id))
  end

  def update_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(), ~w(name email password saltedge_customer_id))
  end

  def login_changeset(model), do: model |> cast(%{}, ~w(), ~w(email password))

  def login_changeset(model, params) do
    model
    |> cast(params, ~w(email password), ~w())
    #|> validate_password
  end

  before_insert :maybe_update_password
  before_update :maybe_update_password

  defp maybe_update_password(changeset) do
    case Ecto.Changeset.fetch_change(changeset, :password) do
      {:ok, password} ->
        changeset
        |> Ecto.Changeset.put_change(:encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
      :error -> changeset
    end
  end

  #@required_fields ~w(name email password saltedge_customer_id saltedge_token)
  #@optional_fields ~w()

  #def changeset(model, params \\ :empty) do
  #  model
  #  |> cast(params, @required_fields, @optional_fields)
  #end

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
