use Mix.Config

config :ewallet_db,
  ecto_repos: [EWalletDB.Repo],
  env: Mix.env(),
  # The `:blockchain_adapter`, `:rootchain_identifier` and `:childchain_identifier`
  # are in `:ewallet_db` app as the we use them for changeset validation and the
  # `:ewallet_db` can be referenced by almost if not all other subapps.
  blockchain_adapter: EthBlockchain.Adapter,
  rootchain_identifier: "ethereum",
  childchain_identifier: "omisego_network",
  settings: [
    :base_url,
    :primary_hot_wallet,
    :min_password_length,
    :file_storage_adapter,
    :aws_bucket,
    :aws_region,
    :aws_access_key_id,
    :aws_secret_access_key,
    :gcs_bucket,
    :gcs_credentials,
    :master_account,
    :pre_auth_token_lifetime,
    :auth_token_lifetime,
    :forget_password_request_lifetime
  ]

config :ewallet_db, EWalletDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: DB.SharedConnectionPool,
  pool_size: {:system, "EWALLET_POOL_SIZE", 15, {String, :to_integer}},
  shared_pool_id: :ewallet,
  migration_timestamps: [type: :naive_datetime_usec]

import_config "#{Mix.env()}.exs"
