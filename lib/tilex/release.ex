defmodule Tilex.Release do
  @app :tilex

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def create_channel(name, twitter_hashtag) do
    Application.load(@app)

    case Ecto.Migrator.with_repo(Tilex.Repo, &create_channel_inner(&1, name, twitter_hashtag)) do
      {:ok, _fun_return, _apps} ->
        :ok

      {:error, reason, _apps} ->
        Logger.error(reason)
        {:error, reason}
    end
  end

  defp create_channel_inner(r, name, twitter_hashtag) do
    r.insert!(%Tilex.Blog.Channel{name: name, twitter_hashtag: twitter_hashtag})
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
