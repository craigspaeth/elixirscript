defmodule ElixirScript.Translator.Spawn do
  alias ESTree.Tools.Builder, as: JS
  alias ElixirScript.Translator
  alias ElixirScript.Translator.Function
  alias ElixirScript.Translator.Call

  def make_spawn(func, env) do
    do_spawn_with_fn(func, env, "spawn")
  end

  def make_spawn_link(func, env) do
    do_spawn_with_fn(func, env, "spawn_link")
  end

  defp do_spawn_with_fn({:fn, _, [{:->, _, [[], body]}]}, env, spawn_func_name) do
    { body, env } = Function.prepare_function_body(body, %{ env | in_process: true })

    js_ast = JS.call_expression(
      JS.member_expression(
        JS.member_expression(
          JS.identifier("Elixir"),
          JS.member_expression(
            JS.identifier("Core"),
            JS.identifier("Functions")
          )
        ),
        JS.identifier("get_global")
      ),
      []
    )


    js_ast = JS.call_expression(
      JS.member_expression(
        JS.member_expression(
          js_ast,
          JS.identifier("processes")
        ),
        JS.identifier(spawn_func_name)
      ),
      [
        JS.function_expression([], [], JS.block_statement(body), true)
      ]
    )

    { js_ast, env }
  end

  def make_spawn(module, fun, args, env) do
    do_spawn_with_mod(module, fun, args, env, "spawn")
  end

  def make_spawn_link(module, fun, args, env) do
    do_spawn_with_mod(module, fun, args, env, "spawn_link")
  end

  defp do_spawn_with_mod(module, fun, args, env, spawn_func_name) do

    js_ast = JS.call_expression(
      JS.member_expression(
        JS.member_expression(
          JS.identifier("Elixir"),
          JS.member_expression(
            JS.identifier("Core"),
            JS.identifier("Functions")
          )
        ),
        JS.identifier("get_global")
      ), [])


    run_func = JS.member_expression(
      JS.member_expression(
        JS.identifier("Elixir"),
        JS.member_expression(
          JS.identifier("Core"),
          JS.identifier("Functions")
        )
      ),
      JS.identifier("run")
    )

    {js, _} = Call.make_function_call(Translator.create_module_name(module, env), fun, args, env)
    %ESTree.CallExpression{ callee: %ESTree.MemberExpression{ object: module, property: %ESTree.Identifier{ name: fun } }, arguments: args } = js

    func_to_run = JS.member_expression(
      module,
      JS.literal(fun),
      true
    )

    js_ast = JS.call_expression(
      JS.member_expression(
        JS.member_expression(
          js_ast,
          JS.identifier("processes")
        ),
        JS.identifier(spawn_func_name)
      ),
      [
        run_func,
        JS.array_expression([func_to_run, JS.array_expression(args)])
      ]
    )

    { js_ast, env }
  end



end
