# Здесь можно собрать вспомогательные функци
defmodule KVstore.Utils do

  def map_to_string(map) when map == %{} do
    "no entries"
  end
  def map_to_string(map) when is_map(map) do
    map |> Enum.map_join("\n", &map_entry_to_string(&1))
  end

  def map_entry_to_string({key, {value, ttl}}) do
    "#{key}: #{value}, #{ttl}"
  end
  def map_entry_to_string(nil) do
    "no changes"
  end

  def map_entry_value_to_string(nil) do
    "entry not found"
  end
  def map_entry_value_to_string({value, ttl}) do
    "#{value}, #{ttl}"
  end
end