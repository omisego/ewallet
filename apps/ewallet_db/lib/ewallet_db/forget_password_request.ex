defmodule EWalletDB.ForgetPasswordRequest do
  @moduledoc """
  Ecto Schema representing a password reset request.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletDB.{Repo, ForgetPasswordRequest, User}
  alias EWalletDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @token_length 32

  schema "forget_password_request" do
    field :token, :string
    belongs_to :user, User, type: UUID
    timestamps()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:token, :user_id])
    |> validate_required([:token, :user_id])
    |> assoc_constraint(:user)
  end

  @doc """
  Retrieves a specific invite by its token.
  """
  def get(user, token) do
    request =
      ForgetPasswordRequest
      |> where([c], c.user_id == ^user.id)
      |> order_by([c], desc: c.inserted_at)
      |> limit(1)
      |> Repo.one()
      |> Repo.preload(:user)

    check_token(request, token)
  end

  defp check_token(nil, _token), do: nil
  defp check_token(request, token) do
    if Crypto.secure_compare(request.token, token), do: request, else: nil
  end

  @doc """
  Deletes all the current requests for a user.
  """
  def delete_all(user) do
    ForgetPasswordRequest
    |> where([f], f.user_id == ^user.id)
    |> Repo.delete_all()

    user
  end

  @doc """
  Generates a forget password request for the given user.
  """
  def generate(user) do
    token = Crypto.generate_key(@token_length)
    {:ok, _} = insert(%{token: token, user_id: user.id})
    ForgetPasswordRequest.get(user, token)
  end

  defp insert(attrs) do
    %ForgetPasswordRequest{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
