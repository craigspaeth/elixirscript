defmodule ElixirScript.Translator.For do
  @moduledoc false
  alias ESTree.Tools.Builder, as: JS
  alias ElixirScript.Translator
  alias ElixirScript.Translator.PatternMatching
  alias ElixirScript.Translator.Primitive
  alias ElixirScript.Translator.Function
  alias ElixirScript.Translator.Utils
  alias ElixirScript.Translator.Identifier

  def make_for(generators, env) do
    ElixirScript.Translator.State.add_module_reference(env.state, env.module, ElixirScript.Collectable)
    args = handle_args(generators, env)

    generators = JS.array_expression(args.generators)

    into = args.into || Primitive.make_list_no_translate([])
    filter = args.filter || JS.function_expression([], [], JS.block_statement([JS.return_statement(JS.identifier("true"))]))
    fun = args.fun

    members = ["Elixir"] ++ Module.split(ElixirScript.Collectable) ++ ["__load"]

    collectable_module = JS.call_expression(
          Identifier.make_namespace_members(members),
          [JS.identifier("Elixir")]
        )


    expression = JS.call_expression(
      JS.member_expression(
        JS.identifier("__P"),
        JS.identifier("clause")
      ),
      [JS.array_expression(args.patterns), fun, filter]
    )

    js_ast = JS.call_expression(
      JS.member_expression(
        Primitive.special_forms(),
        JS.identifier("_for")
      ),
      [expression, generators, collectable_module, into]
    )

    {js_ast, env}
  end

  defp handle_args(generators, env) do
    Enum.reduce(generators, %{generators: [], args: [], filter: nil, fun: nil, into: nil, patterns: []}, fn

      ({:<<>>, _, body}, state) ->
      {bs_parts, collection} = Enum.map_reduce(body, nil, fn
        {:::, _, _} = ast, state ->
          {ast, state}
        {:<-, _, [var, collection]}, _ ->
          {var, collection}
      end)

      {patterns, params, env} = PatternMatching.process_match([{:<<>>, [], bs_parts}], env)

      gen = JS.call_expression(
        JS.member_expression(
          JS.identifier("__P"),
          JS.identifier("bitstring_generator")
        ),
        [hd(patterns), Translator.translate!(collection, env)]
      )

      %{state | generators: state.generators ++ [gen], args: state.args ++ params, patterns: state.patterns ++ patterns}

      ({:<-, _, [identifier, enum]}, state) ->
        {patterns, params, env} = PatternMatching.process_match([identifier], env)

        gen = JS.call_expression(
          JS.member_expression(
            JS.identifier("__P"),
            JS.identifier("list_generator")
          ),
          [hd(patterns), Translator.translate!(enum, env)]
        )

        %{state | generators: state.generators ++ [gen], args: state.args ++ params, patterns: state.patterns ++ patterns}
      ([into: expression], state) ->
        %{state | into: Translator.translate(expression, env)}

      ([into: expression, do: expression2], state) ->
        fun = create_function_expression(expression2, env, state)

        %{state | into: Translator.translate!(expression, env), fun: fun}

      ([do: expression], state) ->
        fun = create_function_expression(expression, env, state)

        %{state | fun: fun}
      (filter, state) ->
        fun = create_function_expression(filter, env, state)

        %{state | filter: fun}
    end)
  end


  defp create_function_expression(ast, env, state) do
    {ast, _} = Function.make_function_body(ast, env)

    JS.function_expression(
      state.args,
      [],
      ast
    )
  end
end
