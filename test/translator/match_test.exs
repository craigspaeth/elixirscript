defmodule ElixirScript.Translator.Match.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate simple match" do
    ex_ast = quote do: a = 1
    js_code = "let [a] = __P.match(__P.variable(), 1);"

    assert_translation(ex_ast, js_code)

    ex_ast = quote do: a = :atom
    js_code = "let [a] = __P.match(__P.variable(), Symbol.for('atom'));"

    assert_translation(ex_ast, js_code)
  end

  test "translate tuple match" do
    ex_ast = quote do
      {a, b} = {1, 2}
    end
    js_code = """
    let [a, b] = __P.match(
      new Bootstrap.Core.Tuple(
        __P.variable(), 
        __P.variable()
      ), 
      new Bootstrap.Core.Tuple(1, 2)
    );
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do: {a, _, c} = {1, 2, 3}
    js_code = """
         let [a, __ignored__, c] = __P.match(new Bootstrap.Core.Tuple(__P.variable(), __P.variable(), __P.variable()), new Bootstrap.Core.Tuple(1, 2, 3));
    """

    assert_translation(ex_ast, js_code)


    ex_ast = quote do
      a = 1
       {^a, _, c} = {1, 2, 3}
    end
    js_code = """
    let [, __ignored__, c] = __P.match(new Bootstrap.Core.Tuple(__P.bound(a), __P.variable(), __P.variable()), new Bootstrap.Core.Tuple(1, 2, 3));
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate bound match" do
    ex_ast = quote do
      a = 1
      ^a = 1
    end

    js_code = """
     let [] = __P.match(__P.bound(a),1);
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate list match" do
    ex_ast = quote do: [a, b] = [1, 2]
    js_code = """
         let [a,b] = __P.match(Object.freeze([__P.variable(), __P.variable()]),Object.freeze([1, 2]));
         let _ref = Object.freeze([a, b]);
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate head/tail match" do
    ex_ast = quote do: [a | b] = [1, 2, 3, 4]
    js_code = """
    let [a,b] = __P.match(__P.headTail(__P.variable(),__P.variable()),Object.freeze([1, 2, 3, 4]));
    let _ref = Object.freeze([a, b]);
    """

    assert_translation(ex_ast, js_code)
  end
end
