defmodule KuberaAdmin.V1.AccountView do
  use KuberaAdmin, :view
  alias KuberaAdmin.V1.{ResponseSerializer, AccountSerializer}

  def render("account.json", %{account: account}) do
    account
    |> AccountSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("accounts.json", %{accounts: accounts}) do
    accounts
    |> AccountSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("empty.json", %{success: success}) do
    %{}
    |> ResponseSerializer.to_json(success: success)
  end
end
