defmodule ElixirScript.Translator.Case.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate case" do

    ex_ast = quote do
      def execute() do
        data = :ok
        case data do
          :ok -> 1
          :error -> nil
        end
      end
    end

    js_code = """
     __P.defmatch(__P.clause([Symbol.for('ok')],function()    {
             return     1;
           }),__P.clause([Symbol.for('error')],function()    {
             return     null;
           })).call(this,data)
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      data = true
      case data do
        false -> value = 13
        true  -> true
      end
    end

    js_code = """
     __P.defmatch(__P.clause([false],function()    {
             let [value] = __P.match(__P.variable(),13);
             return     value;
           }),__P.clause([true],function()    {
             return     true;
           })).call(this,data)
    """

    assert_translation(ex_ast, js_code)



    ex_ast = quote do
      data = :ok
      case data do
        false -> value = 13
        _  -> true
      end
    end

    js_code = """
     __P.defmatch(__P.clause([false],function()    {
             let [value] = __P.match(__P.variable(),13);
             return     value;
           }),__P.clause([__P.variable()],function(__ignored__)    {
             return     true;
           })).call(this,data)
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate case with guard" do
    ex_ast = quote do
      data = :ok
      case data do
        number when number in [1,2,3,4] ->
          value = 13
          _  ->
          true
      end
    end

    js_code = """
     __P.defmatch(__P.clause([__P.variable()],function(number)    {
             let [value] = __P.match(__P.variable(),13);
             return     value;
           },function(number)    {
           return     Elixir.ElixirScript.Bootstrap.Functions.__load(Elixir).contains(number,Object.freeze([1, 2, 3, 4]));
           }),__P.clause([__P.variable()],function(__ignored__)    {
             return     true;
           })).call(this,data)
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate case with multiple guards" do
    ex_ast = quote do
      data = :ok
      case data do
        number when number in [1,2,3,4] when number in [4, 3, 2, 1] ->
          value = 13
        _  ->
          true
      end
    end

    js_code = """
     __P.defmatch(__P.clause([__P.variable()],function(number)    {
             let [value] = __P.match(__P.variable(),13);
             return     value;
           },function(number)    {
           return     Elixir.ElixirScript.Bootstrap.Functions.__load(Elixir).contains(number,Object.freeze([1, 2, 3, 4])) || Elixir.ElixirScript.Bootstrap.Functions.__load(Elixir).contains(number,Object.freeze([4, 3, 2, 1]));
           }),__P.clause([__P.variable()],function(__ignored__)    {
             return     true;
           })).call(this,data)
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate case with multiple statements in body" do
    ex_ast = quote do
      def execute() do
        data = :ok
        case data do
          :ok ->
            :console.info("info")
            Todo.add(data)
          :error ->
            nil
        end
      end
    end

    js_code = """
     __P.defmatch(__P.clause([Symbol.for('ok')],function()    {
             console.info('info');
             return     Todo.add(data);
           }),__P.clause([Symbol.for('error')],function()    {
             return     null;
           })).call(this,data)
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate case with destructing" do
    ex_ast = quote do
      def execute() do
        data = :ok
        case data do
          { one, two } ->
            :console.info(one)
          :error ->
            nil
        end
      end
    end

    js_code = """
__P.defmatch(__P.clause([new Bootstrap.Core.Tuple(__P.variable(), __P.variable())], function(one, two) {
                 return console.info(one);
             }), __P.clause([Symbol.for('error')], function() {
                 return null;
             })).call(this, data);
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate case with nested destructing" do
    ex_ast = quote do
      def execute() do
        data = :error
        case data do
          { {one, two} , three } ->
            :console.info(one)
          :error ->
            nil
        end
      end
    end

    js_code = """
__P.defmatch(__P.clause([new Bootstrap.Core.Tuple(new Bootstrap.Core.Tuple(__P.variable(), __P.variable()), __P.variable())], function(one, two, three) {
                 return console.info(one);
             }), __P.clause([Symbol.for('error')], function() {
                 return null;
             })).call(this, data)
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      data = :error
      case data do
        { one, {two, three} } ->
          :console.info(one)
        :error ->
          nil
      end
    end

    js_code = """
__P.defmatch(__P.clause([new Bootstrap.Core.Tuple(__P.variable(), new Bootstrap.Core.Tuple(__P.variable(), __P.variable()))], function(one, two, three) {
             return console.info(one);
         }), __P.clause([Symbol.for('error')], function() {
             return null;
         })).call(this, data)
    """

    assert_translation(ex_ast, js_code)
  end
end
