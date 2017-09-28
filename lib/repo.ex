defmodule Repo do
  alias Mongo.{DeleteResult, UpdateResult}
  @moduledoc ~S"""
  Simple implementation Mongo-driver.
  Set in your supervisor:
  worker(Mongo, [[name: :mongo, database: mongo_db_name(), hostname: mongo_host(), pool: DBConnection.Poolboy]])
  """

  def insert_one!(coll, doc), do: Mongo.insert_one!(:mongo, coll, doc, pool: DBConnection.Poolboy)
  def insert_one(coll, doc), do: Mongo.insert_one(:mongo, coll, doc, pool: DBConnection.Poolboy)

  def find_one!(coll, doc), do: Mongo.find_one(:mongo, coll, doc, pool: DBConnection.Poolboy)
  def find_one(coll, doc), do: if doc = find_one!(coll, doc), do: {:ok, doc}, else: {:error, nil}

  def find(coll, doc) do
    Mongo.find(:mongo, coll, doc, pool: DBConnection.Poolboy)
      |> Enum.to_list()
  end

  def delete_one!(coll, doc) do
    case Repo.delete_one(coll, doc) do
      :ok -> :ok
      _   -> raise "Can't delete #{inspect doc} from #{inspect coll}"
    end
  end
  def delete_one(coll, doc) do
    case Mongo.delete_one!(:mongo, coll, doc, pool: DBConnection.Poolboy) do
      %DeleteResult{deleted_count: 1} -> :ok
      some                            -> {:error, some}
    end
  end

  def update_one!(coll, filter, doc), do: Mongo.update_one!(:mongo, coll, filter, %{"$seT": doc}, pool: DBConnection.Poolboy)
  def update_one(coll, filter, doc) do
    case update_one!(coll, filter, doc) do
      %UpdateResult{modified_count: 1} -> :ok
      some                             -> {:error, some}
    end
  end
end