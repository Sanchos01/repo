defmodule Repo do
  alias Mongo.{DeleteResult, UpdateResult}
  alias Repo.DataHelper
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

  @spec insert_one!(coll, doc) :: any() | nil
  def insert_one!(coll, doc) do
    case Mongo.insert_one(:mongo, coll, doc, pool: DBConnection.Poolboy) do
      {:ok, obj}         -> BSON.ObjectId.encode!(obj.inserted_id)
      {:error, _message} -> nil
    end
  end

  @spec insert_one(coll, doc) :: {:ok, any()} | {:error, nil}
  def insert_one(coll, doc) do
    case insert_one!(coll, doc) do
      nil -> {:error, nil}
      id  -> {:ok, id}
    end
  end

  @spec find_one(coll, doc, Keyword.t) :: doc | nil
  def find_one!(coll, doc, opts \\ []) do
    Mongo.find_one(:mongo, coll, doc, pool: DBConnection.Poolboy)
      |> doc_to_map()
      |> (fn x -> if struct = opts[:as], do: DataHelper.struct_from_map(x, struct), else: x end).()
  end

  @spec find_one(coll, doc, Keyword.t) :: {:ok, doc} | {:error, nil}
  def find_one(coll, doc, opts \\ []), do: if doc = find_one!(coll, doc, opts), do: {:ok, doc}, else: {:error, nil}

  @spec find(coll, doc, Keyword.t) :: [] | [...]
  def find(coll, doc, opts \\ []) do
    Mongo.find(:mongo, coll, doc, pool: DBConnection.Poolboy)
      |> Enum.to_list()
      |> Enum.map(&doc_to_map/1)
      |> (fn x -> if struct = opts[:as], do: DataHelper.struct_from_map(x, struct), else: x end).()
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

  @spec delete_many!(coll, doc) :: :ok | Exception.t
  def delete_many!(coll, doc) do
    case Repo.delete_many(coll, doc) do
      :ok -> :ok
      _   -> raise "Can't delete #{inspect doc} from #{inspect coll}"
    end
  end

  @spec delete_many(coll, doc) :: :ok | {:error, any()}
  def delete_many(coll, doc) do
    case Mongo.delete_many!(:mongo, coll, doc, pool: DBConnection.Poolboy) do
      %DeleteResult{deleted_count: x} when x > 0 -> {:ok, x}
      some                                       -> {:error, some}
    end
  end

  @spec update_one!(coll, map(), doc, Keyword.t) :: any()
  def update_one!(coll, filter, doc, opts \\ []), do: Mongo.update_one!(:mongo, coll, filter, %{"$set": Map.delete(doc, :__struct__)}, opts ++ [pool: DBConnection.Poolboy])

  @spec update_one(coll, map(), doc, Keyword.t) :: {:ok, any()} | {:error, any()}
  def update_one(coll, filter, doc, opts \\ []) do
    case update_one!(coll, filter, doc, opts) do
      %UpdateResult{modified_count: 1} = res -> {:ok, res}
      some                                   -> {:error, some}
    end
  end

  @spec update_many!(coll, map(), doc, Keyword.t) :: any()
  def update_many!(coll, filter, doc, opts \\ []), do: Mongo.update_many!(:mongo, coll, filter, %{"$set": Map.delete(doc, :__struct__)}, opts ++ [pool: DBConnection.Poolboy])

  @spec update_many(coll, map(), doc, Keyword.t) :: {:ok, any()} | {:error, any()}
  def update_many(coll, filter, doc, opts \\ []) do
    case update_many!(coll, filter, doc, opts) do
      %UpdateResult{modified_count: 0} = res -> {:error, res}
      %UpdateResult{} = res                  -> {:ok, res}
      some                                   -> {:error, some}
    end
  end

  @spec count(coll, map(), Keyword.t) :: any()
  def count(coll, filter, opts \\ []), do: Mongo.count(:mongo, coll, filter, opts ++ [pool: DBConnection.Poolboy])

  @spec aggregate(coll, list(), Keyword.t) :: any()
  def aggregate(coll, pipeline, opts \\ []) do
    Mongo.aggregate(:mongo, coll, pipeline, opts ++ [pool: DBConnection.Poolboy]) |> Enum.to_list()
      |> doc_to_map()
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