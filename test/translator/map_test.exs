defmodule ElixirScript.Translator.Map.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate empty map" do
    ex_ast = quote do: %{}
    js_code = "Object.freeze({})"

    assert_translation(ex_ast, js_code)
  end

  test "translate map with elements" do
    ex_ast = quote do: %{one: "one", two: "two"}
    js_code = "Object.freeze({[Symbol.for('one')]: 'one', [Symbol.for('two')]: 'two'})"

    assert_translation(ex_ast, js_code)
  end

  test "translate map within map" do
    ex_ast = quote do: %{one: "one", two: %{three: "three"}}
    js_code = """
      Object.freeze({
        [Symbol.for('one')]: 'one',
        [Symbol.for('two')]: Object.freeze({
             [Symbol.for('three')]: 'three'
        })
      })
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate map with string keys" do
    ex_ast = quote do: %{"one" => "one", "two" => "two"}
    js_code = """
     Object.freeze({
             one: 'one',     two: 'two'
       })
    """

    assert_translation(ex_ast, js_code)
  end


  test "translate map update" do
    ex_ast = quote do
      map = %{value: 2}
      %{ map | value: 1 }
    end

    js_code = """
         Object.freeze(Object.assign({}, map, Object.freeze({
             [Symbol.for('value')]: 1
         })))
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate variable key" do
    ex_ast = quote do
      key = 1
      value = 2
       %{key => value}
      end

    js_code = "Object.freeze({ [key]: value })"
    assert_translation(ex_ast, js_code)
  end

  test "translate bound map key" do
    ex_ast = quote do
      key = 1
      value = 2
       %{^key => value} = %{key => value}
    end
    js_code = """
         let [value1] = __P.match({
             [key]: __P.variable()
         }, Object.freeze({
             [key]: value
         }));
    """
    assert_translation(ex_ast, js_code)
  end

end
