defmodule ElixirScript.Translator.Capture.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate capture operator with Module, function, and arity" do
    ex_ast = quote do
      fun = &Elixir.Kernel.is_atom/1
    end

    js_code = """
    let [fun] = __P.match(__P.variable(), Elixir.ElixirScript.Kernel.__load(Elixir).is_atom);
    """

    assert_translation(ex_ast, js_code)

  end

  test "translate capture operator with function, and parameters" do

    ex_ast = quote do
      fun = &is_atom(&1)
    end

    js_code = """
     let [fun] = __P.match(__P.variable(),__P.defmatch(__P.clause([__P.variable()],function(__1)    {
             return Elixir.ElixirScript.Kernel.__load(Elixir).is_atom(__1);
           })));
    """

    assert_translation(ex_ast, js_code)


  end

  test "translate capture operator with function, and arity" do

    ex_ast = quote do
      fun = &is_atom/1
    end

    js_code = """
    let [fun] = __P.match(__P.variable(),is_atom);
    """

    assert_translation(ex_ast, js_code)

  end

  test "translate capture operator with anonymous function" do

    ex_ast = quote do
      fun = &(&1 * 2)
    end

    js_code = """
     let [fun] = __P.match(__P.variable(),__P.defmatch(__P.clause([__P.variable()],function(__1)    {
             return     __1 * 2;
           })));
    """

    assert_translation(ex_ast, js_code)

  end

  test "translate capture operator with anonymous function tuple" do

    ex_ast = quote do
      fun = &{&1, &2}
    end

    js_code = """
     let [fun] = __P.match(__P.variable(),__P.defmatch(__P.clause([__P.variable(), __P.variable()],function(__1,__2)    {
             return     new Bootstrap.Core.Tuple(__1,__2);
           })));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      fun = &{&1, &2, &3}
    end

    js_code = """
     let [fun] = __P.match(__P.variable(),__P.defmatch(__P.clause([__P.variable(), __P.variable(), __P.variable()],function(__1,__2,__3)    {
             return     new Bootstrap.Core.Tuple(__1,__2,__3);
           })));
    """

    assert_translation(ex_ast, js_code)


  end

  test "translate capture operator with anonymous functions as parameters" do

    ex_ast = quote do
      def process(a) do
      end

      def execute() do
        Enum.map([], &process(&1))
      end
    end

    js_code = """
     Elixir.ElixirScript.Enum.__load(Elixir).map(Object.freeze([]),__P.defmatch(__P.clause([__P.variable()],function(__1)    {
             return     process(__1);
           })))
    """

    assert_translation(ex_ast, js_code)


    ex_ast = quote do
      def process_event(a) do
      end

      def execute() do
        Elem.keypress(&process_event(&1))
      end
    end

    js_code = """
     Elem.keypress(__P.defmatch(__P.clause([__P.variable()],function(__1)    {
             return     process_event(__1);
           })))
    """

    assert_translation(ex_ast, js_code)
  end
end
