defmodule EWalletAPI.V1.TransactionConsumptionChannel do
  use Phoenix.Channel

  def join("transaction_request_consumption:" <> request_id, params, socket) do
    {:ok, socket}
  end
end
