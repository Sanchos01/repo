defmodule DataHelper do

  def struct_from_map([], _opts), do: []
  def struct_from_map([head|tail], as: a_struct), do: [struct_from_map(head, as: a_struct) | struct_from_map(tail, as: a_struct)]
  def struct_from_map(a_map, as: a_struct), do: struct(a_struct, a_map)
end