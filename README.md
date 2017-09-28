# Repo

Simple implementation Mongo-driver.
Set in your supervisor:
```elixir
worker(Mongo, [[name: :mongo, database: mongo_db_name(), hostname: mongo_host(), pool: DBConnection.Poolboy]])
```

## Installation

The package can be installed by adding `repo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:repo, github: "Sanchos01/repo"}
  ]
end
```
