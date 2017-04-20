defmodule ElixirScript.Translator.With.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate with" do
    ex_ast = quote do
      opts = %{}
      with {:ok, width} <- Map.fetch(opts, :width),
      {:ok, height} <- Map.fetch(opts, :height),
      do: {:ok, width * height}
    end

    js_code = """
    Bootstrap.Core.SpecialForms._with([new Bootstrap.Core.Tuple(Symbol.for('ok'), __P.variable()), function() {
        return Elixir.ElixirScript.Map.__load(Elixir).fetch(opts, Symbol.for('width'));
    }], [new Bootstrap.Core.Tuple(Symbol.for('ok'), __P.variable()), function(width) {
        return Elixir.ElixirScript.Map.__load(Elixir).fetch(opts, Symbol.for('height'));
    }], function(width, height) {
        return new Bootstrap.Core.Tuple(Symbol.for('ok'), width * height);
    })
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate with with bare expression" do
    ex_ast = quote do
      opts = %{}
      with {:ok, width} <- Map.fetch(opts, :width),
      double_width = width * 2,
      {:ok, height} <- Map.fetch(opts, :height),
      do: {:ok, double_width * height}
    end

    js_code = """
    Bootstrap.Core.SpecialForms._with([new Bootstrap.Core.Tuple(Symbol.for('ok'), __P.variable()), function() {
        return Elixir.ElixirScript.Map.__load(Elixir).fetch(opts, Symbol.for('width'));
    }], [__P.variable(), function(width) {
        return width * 2;
    }], [new Bootstrap.Core.Tuple(Symbol.for('ok'), __P.variable()), function(width, double_width) {
        return Elixir.ElixirScript.Map.__load(Elixir).fetch(opts, Symbol.for('height'));
    }], function(width, double_width, height) {
        return new Bootstrap.Core.Tuple(Symbol.for('ok'), double_width * height);
    })
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate with with else" do
    ex_ast = quote do
      opts = %{}
      with {:ok, width} <- Map.fetch(opts, :width),
           {:ok, height} <- Map.fetch(opts, :height) do
        {:ok, width * height}
      else
        :error -> {:error, :wrong_data}
      end
    end

    js_code = """
         Bootstrap.Core.SpecialForms._with([new Bootstrap.Core.Tuple(Symbol.for('ok'), __P.variable()), function() {
             return Elixir.ElixirScript.Map.__load(Elixir).fetch(opts, Symbol.for('width'));
         }], [new Bootstrap.Core.Tuple(Symbol.for('ok'), __P.variable()), function(width) {
             return Elixir.ElixirScript.Map.__load(Elixir).fetch(opts, Symbol.for('height'));
         }], function(width, height) {
             return new Bootstrap.Core.Tuple(Symbol.for('ok'), width * height);
         }, __P.defmatch(__P.clause([Symbol.for('error')], function() {
             return new Bootstrap.Core.Tuple(Symbol.for('error'), Symbol.for('wrong_data'));
         })))
    """

    assert_translation(ex_ast, js_code)
  end
end
