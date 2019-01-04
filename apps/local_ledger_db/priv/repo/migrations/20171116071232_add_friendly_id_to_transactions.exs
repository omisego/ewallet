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

defmodule LocalLedgerDB.Repo.Migrations.AddFriendlyIDToTransactions do
  use Ecto.Migration

  def up do
    alter table(:minted_token) do
      add :friendly_id, :string, null: false
    end
    create unique_index(:minted_token, [:friendly_id])

    alter table(:transaction) do
      remove :minted_token_symbol
      add :minted_token_friendly_id, references(:minted_token, type: :string,
                                                               column: :friendly_id),
                                                               null: false
    end

    flush()

    alter table(:minted_token) do
      remove :symbol
    end
  end

  def down do
    alter table(:minted_token) do
      add :symbol, :string, null: false
    end
    create unique_index(:minted_token, [:symbol])

    alter table(:transaction) do
      remove :minted_token_friendly_id
      add :minted_token_symbol, references(:minted_token, type: :string,
                                                               column: :symbol),
                                                               null: false
    end

    flush()

    alter table(:minted_token) do
      remove :friendly_id
    end
  end
end
