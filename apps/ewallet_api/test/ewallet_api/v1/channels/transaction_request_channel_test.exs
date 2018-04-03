defmodule EWalletAPI.V1.TransactionRequestChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.TransactionRequestChannel
  alias EWalletDB.User

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid request" do
      account = insert(:account)
      request = insert(:transaction_request)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(TransactionRequestChannel,
                              "transaction_request:#{request.external_id}")

      assert res == :ok
      assert socket.topic == "transaction_request:#{request.external_id}"
    end

    test "can't join a channel for an inexisting request" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end

  describe "join/3 as client" do
    test "joins the channel with authenticated user and owned request" do
      {:ok, user} = :user |> params_for() |> User.insert()
      balance = User.get_primary_balance(user)
      request = insert(:transaction_request, balance: balance)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(TransactionRequestChannel,
                              "transaction_request:#{request.external_id}")

      assert res == :ok
      assert socket.topic == "transaction_request:#{request.external_id}"
    end

    test "can't join channel with existing not owned address" do
      user = insert(:user)
      request = insert(:transaction_request)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(TransactionRequestChannel,
                              "transaction_request:#{request.external_id}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with inexisting request" do
      user = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
