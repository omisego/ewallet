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

defmodule EWalletDB.Expirers.AuthExpirer do
  @moduledoc """
  Manages the expiration time of `AuthToken` or `PreAuthToken`.
  """

  alias EWalletDB.{AuthToken, PreAuthToken}

  def get_new_expire_at(0), do: nil

  def get_new_expire_at(lifetime) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), lifetime, :second)
  end

  def expire_or_refresh(nil, _), do: nil

  def expire_or_refresh(token, lifetime) do
    case lifetime do
      0 ->
        token
      _ ->
        expire_or_refresh(:ok, token, token.expire_at || get_new_expire_at(lifetime))
    end
  end

  defp expire_or_refresh(:ok, token, expire_at) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.compare(expire_at)
    |> do_expire_or_refresh(token)
    |> handle_result()
  end

  defp do_expire_or_refresh(:lt, token) do
    refresh(token)
  end

  defp do_expire_or_refresh(_, token) do
    expire(token)
  end

  defp refresh(%AuthToken{} = token) do
    AuthToken.refresh(token, token.user)
  end

  defp refresh(%PreAuthToken{} = token) do
    PreAuthToken.refresh(token, token.user)
  end

  defp expire(%AuthToken{} = token) do
    AuthToken.expire(token, token.user)
  end

  defp expire(%PreAuthToken{} = token) do
    PreAuthToken.expire(token, token.user)
  end

  defp handle_result({:ok, updated_token}) do
    updated_token
  end

  defp handle_result(error) do
    error
  end
end
