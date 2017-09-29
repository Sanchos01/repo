defmodule DataHelper do

  def struct_from_map([], _opts), do: []
  def struct_from_map([head|tail], as: a_struct), do: [struct_from_map(head, as: a_struct) | struct_from_map(tail, as: a_struct)]
  def struct_from_map(map, as: a_struct) do
    attrs = Enum.reduce(map, [], fn {k, v}, acc -> [{String.to_atom(k), v}|acc] end)
    struct(a_struct, attrs)
  end
end