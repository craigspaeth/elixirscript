defmodule ElixirScript.Translate.Module do
  @moduledoc false
  alias ESTree.Tools.Builder, as: J
  alias ElixirScript.Translate.Function
  alias ElixirScript.Translator.Identifier
  alias ElixirScript.State, as: ModuleState

  @doc """
  Translate the given module's ast to
  JavaScript AST
  """
  def compile(module, %{protocol: true} = info, pid) do
    ElixirScript.Translate.Protocol.compile(module, info, pid)
  end

  def compile(module, info, pid) do
    %{
      attributes: attrs, 
      compile_opts: _compile_opts,
      definitions: defs,
      file: _file,
      line: _line, 
      module: ^module, 
      unreachable: unreachable,
      used: used
    } = info

    state = %{
      module: module,
      pid: pid
    }
 
    # Filter so that we only have the
    # Used functions to compile
    reachable_defs = Enum.filter(defs, fn
        { _, type, _, _} when type in [:defmacro, :defmacrop] -> false
        { name, _, _, _} -> not(name in unreachable)
        _ -> true
      end)

    used_defs = if Keyword.has_key?(attrs, :protocol_impl) do
      reachable_defs
    else
      Enum.filter(reachable_defs, fn
        { {:start, 2}, _, _, _ } -> true
        { name, _, _, _} -> name in used
        _ -> false
      end)
    end

    #we combine our function arities
    combined_defs = used_defs
    |> Enum.sort(fn { {name1, arity1}, _, _, _ }, { {name2, arity2}, _, _, _ } -> "#{name1}#{arity1}" < "#{name2}#{arity2}" end)
    |> Enum.group_by(fn {{name, _}, _, _, _ } -> name end)
    |> Enum.map(fn {group, funs} ->
        {_, type, _, _} = hd(funs)
        Enum.reduce(funs, {{group, nil}, type, [], []}, fn {_, _, _, clauses}, {name, type, context, acc_clauses} ->
          {name, type, context, acc_clauses ++ clauses}
        end)
      end)

    { compiled_functions, _ } = combined_defs
    |> Enum.map_reduce(state, &Function.compile(&1, &2))

    exports = make_exports(combined_defs)

    js_ast = ElixirScript.ModuleSystems.Namespace.build(
      module,
      compiled_functions,
      exports,
      nil
    )

    ModuleState.put_module(pid, module, Map.put(info, :js_ast, hd(js_ast))) 
  end

  defp make_exports(reachable_defs) do
    exports = Enum.reduce(reachable_defs, [], fn
      {{name, arity}, :def, _, _}, list ->
        function_name = ElixirScript.Translator.Identifier.make_identifier(name)
          list ++ [J.property(function_name, function_name, :init, true)]
      _, list ->
        list
    end)

    J.object_expression(exports)
  end

  def is_elixir_module(Elixir) do
    true
  end

  def is_elixir_module(module) when is_atom(module) do
    str_module = Atom.to_string(module)

    case str_module do
      "Elixir." <> _ ->
        true
      _ ->
        false
    end
  end

  def is_elixir_module(_) do
    false
  end

  def is_js_module(module, state) do
    cond do
      module in ModuleState.get_javascript_modules(state.pid) ->
        true
      is_elixir_module(module) and hd(Module.split(module)) == "JS" ->
        true
      true ->
        false
    end
  end
end