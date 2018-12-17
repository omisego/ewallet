defmodule EWalletDB.Repo.Seeds.KeySeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Key}
  alias EWalletDB.Seeder

  def seed do
    [
      run_banner: "Seeding the initial access and secret key:",
      argsline: []
    ]
  end

  def run(writer, args) do
    account = Account.get_by(name: "master_account")

    case Key.insert(%{account_uuid: account.uuid, originator: %Seeder{}}) do
      {:ok, key} ->
        {:ok, key} = Preloader.preload_one(key, :account)

        writer.success("""
          Account Name : #{key.account.name}
          Account ID   : #{key.account.id}
          Access key   : #{key.access_key}
          Secret key   : #{key.secret_key}
        """)

        args ++
          [
            {:seeded_ewallet_key_access, key.access_key},
            {:seeded_ewallet_key_secret, key.secret_key}
          ]

      {:error, changeset} ->
        writer.error("  Access/Secret for #{account.name} could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Access/Secret for #{account.name} could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
