defmodule Main do
  def start(:normal, [callback]) do
    callback.("started")

    Enum.each(1..3, fn x -> JS.console.log(x)  end)
  end
end

defmodule TestModuleA do
  def test do
    [1,2,3]
  end
end

defmodule TestModuleB do
  def start(:normal, [callback]) do
    callback.(TestModuleA.test)
  end
end