defmodule ExMoney.LoginLog do
  use ExMoney.Web, :model

  schema "login_logs" do
    field :event, :string
    field :callback, :string
    field :description, :string
    field :params, :map

    belongs_to :login, ExMoney.Login

    timestamps
  end

  @required_fields ~w(event callback login_id)
  @optional_fields ~w(params description)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def by_login_id(id) do
    from ll in ExMoney.LoginLog, where: ll.login_id == ^id
  end
end
