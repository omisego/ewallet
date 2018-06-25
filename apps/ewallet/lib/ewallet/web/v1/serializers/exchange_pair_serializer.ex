defmodule EWallet.Web.V1.ExchangePairSerializer do
  @moduledoc """
  Serializes exchange pairs into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{PaginatorSerializer, TokenSerializer}
  alias EWallet.Web.{Paginator, Date}
  alias EWalletDB.ExchangePair
  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(exchange_pairs) when is_list(exchange_pairs) do
    %{
      object: "list",
      data: Enum.map(exchange_pairs, &serialize/1)
    }
  end

  def serialize(%ExchangePair{} = exchange_pair) do
    exchange_pair = Preloader.preload(exchange_pair, [:from_token, :to_token])

    %{
      object: "exchange_pair",
      id: exchange_pair.id,
      name: exchange_pair.name,
      from_token_id: Assoc.get(exchange_pair, [:from_token, :id]),
      from_token: TokenSerializer.serialize(exchange_pair.from_token),
      to_token_id: Assoc.get(exchange_pair, [:to_token, :id]),
      to_token: TokenSerializer.serialize(exchange_pair.to_token),
      rate: exchange_pair.rate,
      reversible: exchange_pair.reversible,
      created_at: Date.to_iso8601(exchange_pair.inserted_at),
      updated_at: Date.to_iso8601(exchange_pair.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
