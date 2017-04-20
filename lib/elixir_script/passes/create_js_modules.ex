defmodule ElixirScript.Passes.CreateJSModules do
  @moduledoc false
  alias ElixirScript.Translator.Utils
  alias ESTree.Tools.Builder, as: JS

  def execute(compiler_data, opts) do
    namespace_modules = Enum.reduce(compiler_data.data, [], fn
      ({_, %{load_only: true}}, acc) ->
        acc

      ({module_name, module_data}, acc) ->
        if module_data.app == :elixir && opts.import_standard_libs == false do
          acc
        else
          body = generate_namespace_module(
            module_data.type,
            module_name,
            Map.get(module_data, :javascript_module, module_data),
            opts,
            compiler_data.state
          )

          acc ++ List.wrap(body)
        end
    end)

    compiled = compile(namespace_modules, opts)
    Map.put(compiler_data, :compiled, compiled)
  end

  defp generate_namespace_module(:consolidated, module_name, js_module, opts, state) do
    env = ElixirScript.Translator.LexicalScope.module_scope(
      js_module.name,
      Utils.name_to_js_file_name(js_module.name) <> ".js",
      opts.env,
      state,
      opts)

    body = ElixirScript.ModuleSystems.Namespace.build(
      module_name,
      js_module.body,
      js_module.exports,
      env
    )

    body
  end

  defp generate_namespace_module(_, module_name, js_module, _, _) do
    body = ElixirScript.ModuleSystems.Namespace.build(
      module_name,
      js_module.body,
      js_module.exports,
      js_module.env
    )

    body
  end

  defp compile(body, opts) do
    declarator = JS.variable_declarator(
      JS.identifier("Elixir"),
      JS.object_expression([])
    )

    elixir = JS.variable_declaration([declarator], :const)

    table_additions = Enum.map(opts.js_modules, fn
      {module, _} -> add_import_to_table(module)
      {module, _, _} -> add_import_to_table(module)
    end)

    ast = opts.module_formatter.build(
      [],
      opts.js_modules,
      [elixir, pattern_alias(), function_alias(), create_atom_table(), start(), load()] ++ table_additions ++ body,
      JS.identifier("Elixir")
    )

    ast
  end

  def pattern_alias() do
    declarator = JS.variable_declarator(
      JS.identifier("__P"),
      JS.member_expression(
        JS.identifier("Bootstrap"),
        JS.member_expression(
          JS.identifier("Core"),
          JS.identifier("Patterns")
        )
      )
    )

    JS.variable_declaration([declarator], :const)
  end

  def function_alias() do
    declarator = JS.variable_declarator(
      JS.identifier("__F"),
      JS.member_expression(
        JS.identifier("Bootstrap"),
        JS.member_expression(
          JS.identifier("Core"),
          JS.identifier("Functions")
        )
      )
    )

    JS.variable_declaration([declarator], :const)
  end

  def start() do
    JS.assignment_expression(
      :=,
      JS.member_expression(
        JS.identifier("Elixir"),
        JS.identifier("start")
      ),
      JS.function_expression(
        [JS.identifier(:app), JS.identifier(:args)],
        [],
        JS.block_statement([
          JS.call_expression(
            JS.member_expression(
              JS.call_expression(
                JS.member_expression(
                  JS.identifier(:app),
                  JS.identifier("__load")
                ),
                [JS.identifier("Elixir")]
              ),
              JS.identifier("start")
            ),
            [ElixirScript.Translator.Primitive.make_atom(:normal), JS.identifier(:args)]
          )
        ])
      )
    )
  end

  def load do
    JS.assignment_expression(
      :=,
      JS.member_expression(
        JS.identifier("Elixir"),
        JS.identifier("load")
      ),
      JS.function_expression(
        [JS.identifier(:module)],
        [],
        JS.block_statement([
          JS.return_statement(
            JS.call_expression(
              JS.member_expression(
                JS.identifier(:module),
                JS.identifier("__load")
              ),
              [JS.identifier("Elixir")]
            )
          )
        ])
      )
    )
  end

  defp create_atom_table() do
    JS.assignment_expression(
      :=,
      JS.member_expression(
        JS.identifier("Elixir"),
        JS.identifier("__table__")
      ),
      JS.object_expression([])
    )
  end

  defp add_import_to_table(module_name) do
    ref = ElixirScript.Translator.Identifier.make_namespace_members(module_name)
    JS.assignment_expression(
      :=,
      JS.member_expression(
        JS.member_expression(
          JS.identifier("Elixir"),
          JS.identifier("__table__")
        ),
        JS.call_expression(
          JS.member_expression(
            JS.identifier("Symbol"),
            JS.identifier("for")            
          ),
          [JS.literal(ref.name)]
        ),
        true
      ),
      ref
    )
  end
end
