defmodule AdminAPI.V1.AdminAuth.TransactionExportControllerTest do
  use AdminAPI.ConnCase, async: false
  alias EWalletDB.Uploaders
  alias Utils.Helper.PidHelper

  def setup do
    assert Application.get_env(:ewallet, :file_storage_adapter) == "local"
  end

  describe "/transaction.export" do
    test "generates a csv file" do
      admin = get_test_admin()
      insert_list(100, :transaction)
      assert Application.get_env(:ewallet, :file_storage_adapter) == "local"

      response =
        admin_user_request("/transaction.export", %{
          "sort_by" => "created",
          "sort_dir" => "desc"
        })

      assert response["success"] == true
      data = response["data"]

      assert data["adapter"] == "local"
      assert data["completion"] == 1.0
      assert data["status"] == "processing"
      assert data["user_id"] == admin.id

      pid = PidHelper.pid_from_string(data["pid"])
      assert %{export: _} = :sys.get_state(pid)

      response = admin_user_request("/export.get", %{"id" => data["id"]})
      data = response["data"]

      assert data["completion"] == 100
      assert data["status"] == "completed"

      response = admin_user_raw_request("/export.download", %{"id" => data["id"]})

      response
      |> CSV.decode()
      |> Stream.each(fn row ->
        assert [
                 ["id", _],
                 ["idempotency_token", _],
                 ["from_user_id", _]
               ] = row
      end)

      {:ok, _} =
        [
          Application.get_env(:ewallet, :root),
          Uploaders.File.storage_dir(nil, nil)
        ]
        |> Path.join()
        |> File.rm_rf()
    end
  end

  test "returns an 'export:no_records' error when there are no records" do
    response =
      admin_user_request("/transaction.export", %{
        "sort_by" => "created",
        "sort_dir" => "desc"
      })

    assert response["success"] == false
    assert response["data"]["code"] == "export:no_records"
  end
end
