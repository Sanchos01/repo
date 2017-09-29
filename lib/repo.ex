defmodule Repo do
  alias Mongo.{DeleteResult, UpdateResult}
  @moduledoc ~S"""
  Simple implementation Mongo-driver.
  Set in your supervisor:
  worker(Mongo, [[name: :mongo, database: mongo_db_name(), hostname: mongo_host(), pool: DBConnection.Poolboy]])
  """

  @type conn :: DbConnection.Conn
  @type coll :: String.t
  @type doc :: map()
  @type result(t) :: :ok | {:ok, t} | {:error, Mongo.Error.t}
  @type result!(t) :: nil | t | no_return

  @spec insert_one!(coll, doc) :: result!(Mongo.InsertOneResult.t)
  def insert_one!(coll, doc), do: Mongo.insert_one!(:mongo, coll, doc, pool: DBConnection.Poolboy)

  @spec insert_one(coll, doc) :: result(Mongo.InsertOneResult.t)
  def insert_one(coll, doc), do: Mongo.insert_one(:mongo, coll, doc, pool: DBConnection.Poolboy)

  @spec find_one(coll, doc, Keyword.t) :: nil | doc
  def find_one!(coll, doc, opts \\ []) do
    if struct = opts[:as] do
      DataHelper.struct_from_map(Mongo.find_one(:mongo, coll, doc, pool: DBConnection.Poolboy), as: struct)
    else
      Mongo.find_one(:mongo, coll, doc, pool: DBConnection.Poolboy) |> doc_to_map()
    end
  end

  @spec find_one(coll, doc, Keyword.t) :: {:ok, doc} | {:error, nil}
  def find_one(coll, doc, opts \\ []), do: if doc = find_one!(coll, doc, opts), do: {:ok, doc}, else: {:error, nil}

  @spec find(coll, doc, Keyword.t) :: [] | [...]
  def find(coll, doc, opts \\ []) do
    if struct = opts[:as] do
      DataHelper.struct_from_map(Mongo.find(:mongo, coll, doc, pool: DBConnection.Poolboy) |> Enum.to_list(), as: struct)
    else
      Mongo.find(:mongo, coll, doc, pool: DBConnection.Poolboy) |> Enum.to_list() |> Enum.map(&doc_to_map/1)
    end
  end

  @spec delete_one!(coll, doc) :: :ok | Exception.t
  def delete_one!(coll, doc) do
    case Repo.delete_one(coll, doc) do
      :ok -> :ok
      _   -> raise "Can't delete #{inspect doc} from #{inspect coll}"
    end
  end

  @spec delete_one(coll, doc) :: :ok | {:error, any()}
  def delete_one(coll, doc) do
    case Mongo.delete_one!(:mongo, coll, doc, pool: DBConnection.Poolboy) do
      %DeleteResult{deleted_count: 1} -> :ok
      some                            -> {:error, some}
    end
  end

  @spec update_one!(coll, map(), doc) :: result!(Mongo.UpdateResult.t)
  def update_one!(coll, filter, doc), do: Mongo.update_one!(:mongo, coll, filter, %{"$set": doc}, pool: DBConnection.Poolboy)

  @spec update_one(coll, map(), doc) :: :ok | {:error, any()}
  def update_one(coll, filter, doc) do
    case update_one!(coll, filter, doc) do
      %UpdateResult{modified_count: 1} -> :ok
      some                             -> {:error, some}
    end
  end

###############################################

  def doc_to_map(doc) when is_map(doc), do: Map.put(doc, "id", BSON.ObjectId.encode!(doc["_id"])) |> Map.delete("_id")
  def doc_to_map(some), do: some

  def to_struct(kind, attrs) do
  struct = struct(kind)
  Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
    case Map.fetch(attrs, Atom.to_string(k)) do
      {:ok, v} -> %{acc | k => v}
      :error -> acc
      end
    end
  end

  def name_helper(data) do
    name = data.__struct__
        |> Module.split
        |> Enum.join(".")
    to_string(name)
  end
end