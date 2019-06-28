# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.TokenControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.V1.TokenSerializer
  alias EWalletDB.{Mint, Repo, Token, Wallet, Transaction}
  alias ActivityLogger.System
  alias EthBlockchain.DumbAdapter

  describe "/token.all" do
    test_with_auths "returns a list of tokens and pagination data" do
      response = request("/token.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of tokens and pagination data as a provider" do
      response = request("/token.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of tokens according to search_term, sort_by and sort_direction" do
      insert(:token, %{symbol: "XYZ1"})
      insert(:token, %{symbol: "XYZ3"})
      insert(:token, %{symbol: "XYZ2"})
      insert(:token, %{symbol: "ZZZ1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "xYz",
        "sort_by" => "symbol",
        "sort_dir" => "desc"
      }

      response = request("/token.all", attrs)
      tokens = response["data"]["data"]

      assert response["success"]
      assert Enum.count(tokens) == 3
      assert Enum.at(tokens, 0)["symbol"] == "XYZ3"
      assert Enum.at(tokens, 1)["symbol"] == "XYZ2"
      assert Enum.at(tokens, 2)["symbol"] == "XYZ1"
    end

    test_supports_match_any("/token.all", :token, :name)
    test_supports_match_all("/token.all", :token, :name)
  end

  describe "/token.get" do
    test_with_auths "returns a token by the given ID" do
      tokens = insert_list(3, :token)
      # Pick the 2nd inserted token
      target = Enum.at(tokens, 1)
      response = request("/token.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["id"] == target.id
    end

    test_with_auths "returns 'unauthorized' if the given ID was not found" do
      response = request("/token.get", %{"id" => "wrong_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns 'client:invalid_parameter' if id was not provided" do
      response = request("/token.get", %{"not_id" => "token_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end
  end

  describe "/token.stats" do
    test_with_auths "returns the stats for a token" do
      token = insert(:token)
      _mints = insert_list(3, :mint, token_uuid: token.uuid, amount: 100_000)
      response = request("/token.stats", %{"id" => token.id})
      assert response["success"]

      assert response["data"] == %{
               "object" => "token_stats",
               "token_id" => token.id,
               "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
               "total_supply" => 300_000
             }
    end

    test_with_auths "return 'unauthorized' for non existing tokens" do
      token = insert(:token)
      _mints = insert_list(3, :mint, token_uuid: token.uuid)
      response = request("/token.stats", %{"id" => "fale"})

      assert response["success"] == false

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns the stats for a token that hasn't been minted" do
      token = insert(:token)
      response = request("/token.stats", %{"id" => token.id})
      assert response["success"]

      assert response["data"] == %{
               "object" => "token_stats",
               "token_id" => token.id,
               "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
               "total_supply" => 0
             }
    end
  end

  describe "/token.create" do
    test_with_auths "inserts a new token" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "returns an error with decimals > 18 (19 decimals)" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          subunit_to_unit: 10_000_000_000_000_000_000_000
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "inserts a new token with no minting if amount is nil" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: nil
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "fails to create a new token with no minting if amount is 0" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 0
        })

      mint = Mint |> Repo.all() |> Enum.at(0)
      assert mint == nil
      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "mints the given amount of tokens" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 1_000 * 100
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert Token.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.confirmed == true
    end

    test_with_auths "inserts a new token with minting if amount is a string" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: "100"
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert Token.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.confirmed == true
    end

    test_with_auths "returns insert error when attrs are invalid" do
      response =
        request("/token.create", %{
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `symbol` can't be blank."

      inserted = Token |> Repo.all() |> Enum.at(0)
      assert inserted == nil
    end

    defp assert_create_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "name" => target.name,
          "account_uuid" => target.account.uuid,
          "description" => target.description,
          "id" => target.id,
          "metadata" => target.metadata,
          "subunit_to_unit" => target.subunit_to_unit,
          "symbol" => target.symbol
        },
        encrypted_changes: %{"encrypted_metadata" => target.encrypted_metadata}
      )
    end

    test "generates an activity log for an admin request" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_key(), token)
    end

    defp assert_create_minting_logs(logs, originator, token: token, mint: mint) do
      genesis = Wallet.get("gnis000000000000")

      transaction =
        Transaction
        |> get_last_inserted()
        |> Repo.preload([:from_token, :to_wallet, :to_account, :to_token])

      assert Enum.count(logs) == 7

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: token,
        changes: %{
          "name" => token.name,
          "account_uuid" => token.account.uuid,
          "description" => token.description,
          "id" => token.id,
          "metadata" => token.metadata,
          "subunit_to_unit" => token.subunit_to_unit,
          "symbol" => token.symbol
        },
        encrypted_changes: %{"encrypted_metadata" => token.encrypted_metadata}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: mint,
        changes: %{
          "account_uuid" => mint.account.uuid,
          "amount" => mint.amount,
          "token_uuid" => mint.token.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: :system,
        target: genesis,
        changes: %{
          "address" => "gnis000000000000",
          "identifier" => "genesis",
          "name" => "genesis"
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(3)
      |> assert_activity_log(
        action: "insert",
        originator: mint,
        target: transaction,
        changes: %{
          "from" => "gnis000000000000",
          "from_amount" => 100,
          "from_token_uuid" => transaction.from_token.uuid,
          "idempotency_token" => transaction.idempotency_token,
          "to" => transaction.to_wallet.address,
          "to_account_uuid" => transaction.to_account.uuid,
          "to_amount" => 100,
          "to_token_uuid" => transaction.to_token.uuid
        },
        encrypted_changes: %{
          "payload" => %{
            "amount" => 100,
            "description" => nil,
            "idempotency_token" => transaction.idempotency_token,
            "token_id" => transaction.to_token.id
          }
        }
      )

      logs
      |> Enum.at(4)
      |> assert_activity_log(
        action: "update",
        originator: transaction,
        target: mint,
        changes: %{
          "transaction_uuid" => transaction.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(5)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction,
        changes: %{
          "local_ledger_uuid" => transaction.local_ledger_uuid,
          "status" => "confirmed"
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(6)
      |> assert_activity_log(
        action: "update",
        originator: transaction,
        target: mint,
        changes: %{"confirmed" => true},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log when minting for an admin request" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      mint = Mint |> get_last_inserted() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_minting_logs(get_test_admin(), token: token, mint: mint)
    end

    test "generates an activity log when minting for a provider request" do
      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      mint = Mint |> get_last_inserted() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_minting_logs(get_test_key(), token: token, mint: mint)
    end
  end

  describe "/token.update" do
    test_with_auths "updates an existing token" do
      token = insert(:token)

      response =
        request("/token.update", %{
          id: token.id,
          name: "updated name",
          description: "updated description",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["name"] == "updated name"
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
    end

    test_with_auths "fails to update an existing token with name = nil" do
      token = insert(:token)

      response =
        request("/token.update", %{
          id: token.id,
          name: nil
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `name` can't be blank."
    end

    test_with_auths "Raises invalid_parameter error if id is missing" do
      response = request("/token.update", %{name: "Bitcoin"})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `id` is required.",
               "messages" => nil
             }
    end

    test_with_auths "Raises 'unauthorized' error if the token can't be found" do
      response = request("/token.update", %{id: "fake", name: "Bitcoin"})

      refute response["success"]

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "metadata" => target.metadata,
          "description" => target.description,
          "name" => target.name
        },
        encrypted_changes: %{"encrypted_metadata" => target.encrypted_metadata}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.update", %{
          id: token.id,
          name: "updated name",
          description: "updated description",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_update_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.update", %{
          id: token.id,
          name: "updated name",
          description: "updated description",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_update_logs(get_test_key(), token)
    end
  end

  describe "/token.enable_or_disable" do
    test_with_auths "disables an existing token" do
      token = insert(:token)

      response =
        request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["enabled"] == false
    end

    test_with_auths "fails to disable an existing token with enabled = nil" do
      token = insert(:token)

      response =
        request("/token.enable_or_disable", %{
          id: token.id,
          enabled: nil
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `enabled` can't be blank."
    end

    test_with_auths "Raises invalid_parameter error if id is missing" do
      response = request("/token.enable_or_disable", %{enabled: false, originator: %System{}})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `id` is required.",
               "messages" => nil
             }
    end

    test_with_auths "Raises token_not_found error if the token can't be found" do
      response = request("/token.enable_or_disable", %{id: "fake", enabled: false})

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    defp assert_enable_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "enabled" => target.enabled
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_enable_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_enable_logs(get_test_key(), token)
    end
  end

  describe "/token.upload_avatar" do
    test_with_auths "uploads an avatar for the specified token" do
      token = insert(:token)

      attrs = %{
        id: token.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/token.upload_avatar", attrs)

      assert response["success"]
      assert response["data"]["object"] == "token"

      assert response["data"]["avatar"]["large"] =~
               "http://localhost:4000/public/uploads/test/token/avatars/#{attrs.id}/large.png?v="

      assert response["data"]["avatar"]["original"] =~
               "http://localhost:4000/public/uploads/test/token/avatars/#{attrs.id}/original.jpg?v="

      assert response["data"]["avatar"]["small"] =~
               "http://localhost:4000/public/uploads/test/token/avatars/#{attrs.id}/small.png?v="

      assert response["data"]["avatar"]["thumb"] =~
               "http://localhost:4000/public/uploads/test/token/avatars/#{attrs.id}/thumb.png?v="
    end

    test_with_auths "fails to upload an invalid file" do
      token = insert(:token)

      attrs = %{
        "id" => token.id,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/file.json",
          filename: "file.json"
        }
      }

      response = request("/token.upload_avatar", attrs)

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "returns an error when 'avatar' is not sent" do
      token = insert(:token)

      attrs = %{
        "id" => token.id
      }

      response = request("/token.upload_avatar", attrs)

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "removes the avatar from a token" do
      token = insert(:token)

      attrs = %{
        id: token.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/token.upload_avatar", attrs)
      assert response["success"]

      attrs = %{
        id: token.id,
        avatar: nil
      }

      response = request("/token.upload_avatar", attrs)

      assert response["success"]
      token = Token.get(attrs.id)
      assert token.avatar == nil
    end

    test_with_auths "removes the avatar from a token with empty string" do
      token = insert(:token)

      attrs = %{
        id: token.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/token.upload_avatar", attrs)
      assert response["success"]
      token = Token.get(attrs.id)
      assert token.avatar != nil

      attrs = %{
        id: token.id,
        avatar: ""
      }

      response = request("/token.upload_avatar", attrs)

      assert response["success"]
      token = Token.get(attrs.id)
      assert token.avatar == nil
    end

    test_with_auths "removes the avatar from a token with 'null' string" do
      token = insert(:token)

      attrs = %{
        id: token.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/token.upload_avatar", attrs)
      assert response["success"]

      attrs = %{
        id: token.id,
        avatar: "null"
      }

      response = request("/token.upload_avatar", attrs)

      assert response["success"]
      token = Token.get(attrs.id)
      assert token.avatar == nil
    end

    test_with_auths "returns :invalid_parameter error when id is not given" do
      response = request("/token.upload_avatar", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "`id` and `avatar` are required"
    end

    test_with_auths "returns 'unauthorized' if the given token ID was not found" do
      attrs = %{
        id: "fake",
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/token.upload_avatar", attrs)

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end

  describe "/token.get_erc20_capabilities" do
    test_with_auths "get erc20 attributes of a contract address" do
      response =
        request("/token.get_erc20_capabilities", %{
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      assert response["success"]
      assert response["data"]["object"] == "erc20_attrs"
      assert response["data"]["name"] == "OMGToken"
      assert response["data"]["symbol"] == "OMG"
      assert response["data"]["decimals"] == 18
      assert response["data"]["total_supply"] == 100_000_000_000_000_000_000
    end

    test_with_auths "fails to get attributes for an invalid address" do
      response =
        request("/token.get_erc20_capabilities", %{
          contract_address: DumbAdapter.invalid_erc20_contract_address()
        })

      refute response["success"]
      assert response["data"]["code"] == "token:not_erc20"

      assert response["data"]["description"] ==
               "The provided contract address does not implement the required erc20 functions."
    end

    test_with_auths "Raises invalid_parameter error if contract_address is missing" do
      response = request("/token.get_erc20_capabilities", %{})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided. `contract_address` is required and must be in a valid format.",
               "messages" => nil
             }
    end

    test_with_auths "Raises invalid_parameter error if contract_address is in invalid format" do
      response = request("/token.get_erc20_capabilities", %{contract_address: "123"})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided. `contract_address` is required and must be in a valid format.",
               "messages" => nil
             }
    end
  end

  describe "/token.set_contract_address" do
    test_with_auths "sets the blockchain address to a valid existing token" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})

      response =
        request("/token.set_contract_address", %{
          id: token.id,
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["blockchain_address"] == DumbAdapter.valid_erc20_contract_address()
      assert response["data"]["blockchain_status"] == Token.blockchain_status_confirmed()
    end

    test_with_auths "fails to update an existing token if contract_address is missing" do
      token = insert(:token)

      response =
        request("/token.set_contract_address", %{
          id: token.id
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `id` and `contract_address` are required and must be in a valid format."
    end

    test_with_auths "fails to update an existing token if contract_address is invalid" do
      token = insert(:token)

      response =
        request("/token.set_contract_address", %{
          id: token.id,
          contract_address: "123"
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `id` and `contract_address` are required and must be in a valid format."
    end

    test_with_auths "fails to update an existing token if id is missing" do
      response =
        request("/token.set_contract_address", %{
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `id` and `contract_address` are required and must be in a valid format."
    end

    test_with_auths "fails to update an existing token if decimals don't match" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1})

      response =
        request("/token.set_contract_address", %{
          id: token.id,
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      refute response["success"]
      assert response["data"]["code"] == "token:not_matching_contract_info"

      assert response["data"]["description"] ==
               "The decimal count or the symbol obtained from the contract at the specified address don't match the token."
    end

    test_with_auths "fails to update an existing token if symbol don't match" do
      token = insert(:token, %{symbol: "BTC", subunit_to_unit: 1_000_000_000_000_000_000})

      response =
        request("/token.set_contract_address", %{
          id: token.id,
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      refute response["success"]
      assert response["data"]["code"] == "token:not_matching_contract_info"

      assert response["data"]["description"] ==
               "The decimal count or the symbol obtained from the contract at the specified address don't match the token."
    end

    test_with_auths "Raises 'unauthorized' error if the token can't be found" do
      response =
        request("/token.set_contract_address", %{
          id: "fake",
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      refute response["success"]

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    defp assert_set_contract_address_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "blockchain_address" => target.blockchain_address,
          "blockchain_status" => target.blockchain_status
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.set_contract_address", %{
          id: token.id,
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_set_contract_address_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})

      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.set_contract_address", %{
          id: token.id,
          contract_address: DumbAdapter.valid_erc20_contract_address()
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_set_contract_address_logs(get_test_key(), token)
    end
  end
end
