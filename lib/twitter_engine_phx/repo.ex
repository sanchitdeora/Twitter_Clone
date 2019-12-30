defmodule TwitterEnginePhx.Repo do
  use Ecto.Repo,
    otp_app: :twitter_engine_phx,
    adapter: Ecto.Adapters.Postgres
end
