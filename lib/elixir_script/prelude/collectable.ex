defprotocol ElixirScript.Collectable do
  @moduledoc false  
  def into(collectable)
end

defimpl ElixirScript.Collectable, for: List do
  def into(original) do
    collector = fn
      list, {:cont, x} -> [x | list]
      list, :done -> original ++ Enum.reverse(list)
      _, :halt -> :ok
    end

    {[], collector}
  end
end


defimpl ElixirScript.Collectable, for: BitString do
  def into(original) do
    collector = fn
      acc, {:cont, x} when is_binary(x) -> acc <> x
      acc, :done -> acc
      _, :halt -> :ok
    end

    {original, collector}
  end
end


defimpl Collectable, for: Map do
  def into(original) do
    collector = fn
      map, {:cont, {k, v}} -> Map.put(k, v, map)
      map, :done -> map
      _, :halt -> :ok
    end


    {original, collector}
  end
end