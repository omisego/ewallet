# Copyright 2018 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.ProviderAuth.ConfigurationControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletConfig.{Config, StoredSetting}

  describe "/configuration.get" do
    test "returns a list of settings" do
      response = provider_request("/configuration.all", %{})
      default_settings = Application.get_env(:ewallet_config, :default_settings)
      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])
      assert length(response["data"]["data"]) == Enum.count(default_settings)
    end
  end

  describe "/configuration.update" do
    test "updates one setting", meta do
      response =
        provider_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true
      assert response["data"]["data"]["base_url"] != nil
      assert response["data"]["data"]["base_url"]["value"] == "new_base_url.example"
    end

    test "updates a list of settings", meta do
      response =
        provider_request("/configuration.update", %{
          "aws_access_key_id" => "asd",
          "aws_bucket" => "asd",
          "aws_region" => "asdz",
          "aws_secret_access_key" => "asdasdasdasdasd",
          "config_pid" => meta[:config_pid]
        })

      assert response["success"] == true
      data = response["data"]["data"]

      assert data["aws_access_key_id"]["value"] == "asd"
      assert data["aws_bucket"]["value"] == "asd"
      assert data["aws_region"]["value"] == "asdz"
      assert data["aws_secret_access_key"]["value"] == "asdasdasdasdasd"
    end

    test "updates a list of settings with failures", meta do
      response =
        provider_request("/configuration.update", %{
          base_url: "new_base_url.example",
          redirect_url_prefixes: ["new_base_url.example", "something.else"],
          fake_setting: "my_value",
          max_per_page: true,
          email_adapter: "fake",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true
      data = response["data"]["data"]

      assert data["base_url"] != nil
      assert data["base_url"]["value"] == "new_base_url.example"

      assert data["redirect_url_prefixes"] != nil
      assert data["redirect_url_prefixes"]["value"] == ["new_base_url.example", "something.else"]

      assert data["email_adapter"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided. `value` must be one of 'smtp', 'local', 'test'.",
               "messages" => %{"value" => ["value_not_allowed"]},
               "object" => "error"
             }

      assert data["fake_setting"] == %{
               "code" => "setting:not_found",
               "object" => "error",
               "description" => "The setting could not be inserted.",
               "messages" => nil
             }

      assert data["max_per_page"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `value` must be of type 'integer'.",
               "messages" => %{"value" => ["invalid_type_for_value"]},
               "object" => "error"
             }
    end

    test "reloads app env", meta do
      response =
        provider_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true

      assert Application.get_env(:admin_api, :base_url, "new_base_url.example")
    end

    test "generates an activity log", meta do
      timestamp = DateTime.utc_now()

      response =
        provider_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true
      setting = Config.get_setting(:base_url)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: %StoredSetting{uuid: setting.uuid},
        changes: %{"data" => %{"value" => "new_base_url.example"}, "position" => setting.position},
        encrypted_changes: %{}
      )
    end
  end
end
