defmodule AdminAPI.V1.SelfControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date

  describe "/me.get" do
    test "responds with user data" do
      response = user_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end

  describe "/me.get_accounts" do
    test "responds with a list of accounts" do
      account     = insert(:account)
      _membership = insert(:membership, %{user: get_test_user(), account: account})

      assert user_request("/me.get_accounts") ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [%{
              "object" => "account",
              "id" => account.id,
              "name" => account.name,
              "description" => account.description,
              "master" => account.master,
              "created_at" => Date.to_iso8601(account.inserted_at),
              "updated_at" => Date.to_iso8601(account.updated_at)
            }]
          }
        }
    end
  end
end
