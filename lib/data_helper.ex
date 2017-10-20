defmodule DataHelper do

  def struct_from_map([], a_struct), do: []
  def struct_from_map([head|tail], a_struct), do: [struct_from_map(head, a_struct) | struct_from_map(tail, a_struct)]
  def struct_from_map(map, a_struct) when is_map(map) do
    attrs = Enum.reduce(map, [], fn {k, v}, acc -> [{String.to_atom(k), v}|acc] end)
    struct(a_struct, attrs)
  end
  def struct_from_map(_some, _a_struct), do: nil
end