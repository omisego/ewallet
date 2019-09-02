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

defmodule EWalletDB.BlockchainDepositWalletBalance do
  @moduledoc """
  Ecto Schema representing a blockchain deposit wallet.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  import EWalletDB.Helpers.Preloader

  alias Ecto.UUID

  alias EWalletDB.{
    Repo,
    BlockchainDepositWalletBalance,
    BlockchainDepositWallet,
    BlockchainHDWallet,
    Token,
    Wallet
  }

  alias ActivityLogger.System

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_deposit_wallet_balance" do
    field(:amount, Utils.Types.Integer)
    field(:blockchain_identifier, :string)

    belongs_to(
      :blockchain_deposit_wallet,
      BlockchainDepositWallet,
      foreign_key: :blockchain_deposit_wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
      references: :uuid,
      type: UUID
    )

    activity_logging()
    timestamps()
  end

  defp changeset(%BlockchainDepositWalletBalance{} = wallet, attrs) do
    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :amount,
        :blockchain_deposit_wallet_address,
        :token_uuid,
        :blockchain_identifier
      ],
      required: [:amount, :blockchain_identifier, :blockchain_deposit_wallet_address, :token_uuid]
    )
    |> validate_immutable(:blockchain_deposit_wallet_address)
    |> validate_immutable(:token_uuid)
    |> assoc_constraint(:blockchain_deposit_wallet)
    |> assoc_constraint(:token)
  end

  def all_with_balances([first | tokens], blockchain_identifier) when not is_nil(first) do
    query =
      where(
        BlockchainDepositWalletBalance,
        [b],
        b.amount > 0 and b.token_uuid == ^first.uuid and
          b.blockchain_identifier == ^blockchain_identifier
      )

    tokens
    |> Enum.reduce(query, fn token, query ->
      or_where(
        query,
        [b],
        b.amount > 0 and b.token_uuid == ^token.uuid and
          b.blockchain_identifier == ^blockchain_identifier
      )
    end)
    |> Repo.all()
  end

  def all_with_balances(_tokens, _blockchain_identifier), do: []

  def create_or_update_all(%{address: address, balances: balances}, blockchain_identifier) do
    Enum.map(balances, fn %{amount: amount, token: token} ->
      %BlockchainDepositWalletBalance{}
      |> changeset(%{
        blockchain_deposit_wallet_address: address,
        token_uuid: token.uuid,
        amount: amount,
        blockchain_identifier: blockchain_identifier,
        originator: %System{}
      })
      |> Repo.insert(
        on_conflict: [set: [amount: amount]],
        conflict_target: [:blockchain_deposit_wallet_address, :blockchain_identifier, :token_uuid]
      )
    end)
  end
end
