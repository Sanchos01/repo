defmodule Repo.DataHelper do

  def struct_from_map([], _a_struct), do: []
  def struct_from_map([head|tail], a_struct), do: [struct_from_map(head, a_struct) | struct_from_map(tail, a_struct)]
  def struct_from_map(map, a_struct) when is_map(map) do
    attrs = Enum.reduce(map, [], fn {k, v}, acc ->
        if key = safe_to_exist_atom(k), do: [{key, v}|acc], else: acc
      end)
    struct(a_struct, attrs)
  end
  def struct_from_map(_some, _a_struct), do: nil

  defp safe_to_exist_atom(string) do
    try do
      String.to_existing_atom(string)
    rescue
      _e -> nil
    end
  end
end