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

defmodule EWallet.TransactionTracker do
  @moduledoc """
  This module is a GenServer started dynamically for a specific eWallet transaction
  It will registers itself with the blockchain adapter to receive events about
  a given transactions and act on it
  """
  use GenServer, restart: :temporary
  require Logger

  alias EWallet.{BlockchainHelper, BlockchainTransactionState, BlockchainTransactionGate}
  alias ActivityLogger.System

  # TODO: handle failed transactions

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(%{transaction: transaction} = state) do
    IO.inspect("Starting tracker for transaction...")
    adapter = BlockchainHelper.adapter()
    :ok = adapter.subscribe(:transaction, transaction.blockchain_tx_hash, self())
    {:ok, state}
  end

  def handle_cast(
        {:confirmations_count, transaction_receipt, confirmations_count},
        %{transaction: transaction} = state
      ) do
    IO.inspect("Confirmation count cast")
    IO.inspect(confirmations_count)
    IO.inspect(transaction.blockchain_tx_hash)
    IO.inspect(transaction_receipt.transaction_hash)
    case transaction.blockchain_tx_hash == transaction_receipt.transaction_hash do
      true ->
        adapter = BlockchainHelper.adapter()
        threshold = Application.get_env(:ewallet, :blockchain_confirmations_threshold)
        IO.inspect("Threshold: #{threshold}")

        if is_nil(threshold) do
          Logger.warn("Blockchain Confirmations Threshold not set in configuration: using 10.")
        end

        update_confirmations_count(
          adapter,
          state,
          confirmations_count,
          confirmations_count > (threshold || 10)
        )

      false ->
        # TODO: Remove this
        raise "Error! Hashes do not match"
        {:noreply, state}
    end
  end

  # Threshold reached, finalizing the transaction...
  defp update_confirmations_count(
         adapter,
         %{transaction: transaction} = state,
         confirmations_count,
         true
       ) do
    IO.inspect("Confirming tx...")
    {:ok, transaction} =
      BlockchainTransactionState.transition_to(
        :blockchain_confirmed,
        transaction,
        confirmations_count,
        %System{}
      )

    {:ok, transaction} = BlockchainTransactionGate.handle_local_insert(transaction)

    # Unsubscribing from the blockchain subapp
    :ok = adapter.unsubscribe(:transaction, transaction.blockchain_tx_hash, self())

    case is_nil(state[:registry]) do
      true ->
        {:stop, :normal, Map.put(state, :transaction, transaction)}

      false ->
        :ok = GenServer.cast(state[:registry], {:stop_tracker, transaction.uuid})
        {:noreply, Map.put(state, :transaction, transaction)}
    end
  end

  # Treshold not reached yet, updating and continuing to track...
  defp update_confirmations_count(
         _adapter,
         %{transaction: transaction} = state,
         confirmations_count,
         false
       ) do
    IO.inspect("Updating confirmation counts: #{confirmations_count}")

    {:ok, transaction} =
      BlockchainTransactionState.transition_to(
        :pending_confirmations,
        transaction,
        confirmations_count,
        %System{}
      )

    {:noreply, Map.put(state, :transaction, transaction)}
  end
end
