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

defmodule EthBlockchain.ErrorHandler do
  @moduledoc """
  Handles errors by mapping the error to its response code and description.
  """
  alias EWallet.Web.V1.ErrorHandler, as: EWalletErrorHandler
  alias EWallet.Web.V1.ResponseSerializer
  alias EthBlockchain.Adapter

  @errors %{
    token_not_erc20: %{
      code: "token:not_erc20",
      description:
        "The provided contract address does not implement the required erc20 functions."
    },
    unknow_error: %{
      code: "blockchain:unknow_error",
      description: "Something went wrong when communicating with the blockchain."
    }
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{
          required(atom()) => %{code: String.t(), description: String.t()}
        }
  def errors() do
    {:get_errors}
    |> Adapter.call(adapter, pid)
    |> Map.merge(@errors, fn _k, _shared, current ->
      current
    end)
  end

  @doc """
  Build the response with the corresponding error.
  """
  def handle_error(code, attrs) do
    {:error, code, attrs}
  end

  def handle_error(code) do
    {:error, code}
  end
end
