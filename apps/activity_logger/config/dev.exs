use Mix.Config

config :activity_logger, ActivityLogger.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DATABASE_URL", "postgres://localhost/ewallet_dev"},
  migration_timestamps: [type: :naive_datetime_usec]
