{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EWalletDB.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(EWalletConfig.Repo, :manual)
