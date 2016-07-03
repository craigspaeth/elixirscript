defmodule ElixirScript.Translator.Block do
  @moduledoc false
  alias ESTree.Tools.Builder, as: JS
  alias ElixirScript.Translator

  def make_block(expressions, env) do
    { list, env } = Enum.map_reduce(expressions, env, fn(x, updated_env) ->
      {item, updated_env } = Translator.translate(x, updated_env)
      {process_call(item, env), updated_env}
    end)

    { JS.block_statement(list), env }
  end

  def process_call(item, %ElixirScript.Translator.LexicalScope{ context: :guard }) do
    item
  end

  def process_call(item, _) do
    case item do
      %ESTree.CallExpression{
        callee: %ESTree.MemberExpression{
          object: %ESTree.MemberExpression{
            object: %ESTree.Identifier{name: "Elixir"},
            property: %ESTree.MemberExpression{
              object: %ESTree.Identifier{name: "Core"},
              property: %ESTree.Identifier{name: "Functions"}
            }
          },
          property: %ESTree.Identifier{name: "run"}
       }
      } ->
        JS.yield_expression(item, true)
      %ESTree.ReturnStatement{ argument: %ESTree.YieldExpression{}} ->
        item
      %ESTree.ReturnStatement{} ->
        %{item | argument: JS.yield_expression(item.argument, true) }
     _ ->
       item
   end
  end

end
