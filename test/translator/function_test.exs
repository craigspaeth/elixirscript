defmodule ElixirScript.Translator.Function.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate functions" do
    ex_ast = quote do
      def test1() do
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([],function()    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha,beta)    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
        a = alpha
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha,beta)    {
             let [a] = __P.match(__P.variable(),alpha);
             return     a;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
        if 1 == 1 do
          1
        else
          2
        end
      end
    end

    js_code = """
         const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha,beta)    {
             return     __P.defmatch(__P.clause([__P.variable()],function(x)    {
             return     2;
           },function(x)    {
           return x === null || x === false;
           }),__P.clause([__P.variable()],function(__ignored__)    {
             return     1;
           })).call(this,1 == 1);
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
        if 1 == 1 do
          if 2 == 2 do
            4
          else
            a = 1
          end
        else
          2
        end
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()], function(alpha, beta) {
         return __P.defmatch(__P.clause([__P.variable()], function(x) {
             return 2;
         }, function(x) {
             return x === null || x === false;
         }), __P.clause([__P.variable()], function(__ignored__) {
             return __P.defmatch(__P.clause([__P.variable()], function(x) {
                 let [a] = __P.match(__P.variable(), 1);

                 return a;
             }, function(x) {
                 return x === null || x === false;
             }), __P.clause([__P.variable()], function(__ignored__1) {
                 return 4;
             })).call(this, 2 == 2);
         })).call(this, 1 == 1);
     }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
        {a, b} = {1, 2}
      end
    end

    js_code = """
         const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()], function(alpha, beta) {
             let [a, b] = __P.match(new Bootstrap.Core.Tuple(__P.variable(), __P.variable()), new Bootstrap.Core.Tuple(1, 2));

             let _ref = new Bootstrap.Core.Tuple(a, b);

             return _ref;
         }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate function calls" do
    ex_ast = quote do
      defmodule Taco do
        def test1() do
        end
      end


      Taco.test1()
    end

    js_code = "Elixir.Taco.__load(Elixir).test1()"

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defmodule Taco do
        def test1(a, b) do
        end
      end

      Taco.test1(3, 2)
    end

    js_code = "Elixir.Taco.__load(Elixir).test1(3,2)"

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defmodule Taco do
        def test1(a, b) do
        end

        def test2(a) do
        end
      end

      Taco.test1(Taco.test2(1), 2)
    end

    js_code = "Elixir.Taco.__load(Elixir).test1(Elixir.Taco.__load(Elixir).test2(1), 2)"

    assert_translation(ex_ast, js_code)
  end


  test "translate anonymous functions" do
    ex_ast = quote do
      list = []
      Enum.map(list, fn(x) -> x * 2 end)
    end

    js_code = """
     Elixir.ElixirScript.Enum.__load(Elixir).map(list,__P.defmatch(__P.clause([__P.variable()],function(x)    {
             return     x * 2;
           })))
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate function arity" do
    ex_ast = quote do
      defmodule Example do

        defp example() do
        end

        defp example(oneArg) do
        end

        defp example(oneArg, twoArg) do
        end

        defp example(oneArg, twoArg, redArg) do
        end

        defp example(oneArg, twoArg, redArg, blueArg) do
        end
      end
    end

    js_code = """
         const example = __P.defmatch(__P.clause([],function()    {
             return     null;
           }),__P.clause([__P.variable()],function(oneArg)    {
             return     null;
           }),__P.clause([__P.variable(), __P.variable()],function(oneArg,twoArg)    {
             return     null;
           }),__P.clause([__P.variable(), __P.variable(), __P.variable()],function(oneArg,twoArg,redArg)    {
             return     null;
           }),__P.clause([__P.variable(), __P.variable(), __P.variable(), __P.variable()],function(oneArg,twoArg,redArg,blueArg)    {
             return     null;
           }));
    """
    assert_translation(ex_ast, js_code)


    ex_ast = quote do
      defmodule Example do
        def example() do
        end

        def example(oneArg) do
        end

        def example(oneArg, twoArg) do
        end

        def example(oneArg, twoArg, redArg) do
        end

        def example(oneArg, twoArg, redArg, blueArg) do
        end
      end
    end

    js_code = """
         const example = __P.defmatch(__P.clause([],function()    {
             return     null;
           }),__P.clause([__P.variable()],function(oneArg)    {
             return     null;
           }),__P.clause([__P.variable(), __P.variable()],function(oneArg,twoArg)    {
             return     null;
           }),__P.clause([__P.variable(), __P.variable(), __P.variable()],function(oneArg,twoArg,redArg)    {
             return     null;
           }),__P.clause([__P.variable(), __P.variable(), __P.variable(), __P.variable()],function(oneArg,twoArg,redArg,blueArg)    {
             return     null;
           }));
    """
    assert_translation(ex_ast, js_code)


    ex_ast = quote do
      defmodule Example do
        def example(oneArg) do
        end
      end
    end

    js_code = """
         const example = __P.defmatch(__P.clause([__P.variable()],function(oneArg)    {
             return     null;
           }));
    """
    assert_translation(ex_ast, js_code)

  end

  test "test Elixir.Kernel function" do
    ex_ast = quote do
      is_atom(:atom)
    end

    js_code = "Elixir.ElixirScript.Kernel.__load(Elixir).is_atom(Symbol.for('atom'))"

    assert_translation(ex_ast, js_code)
  end

  test "guards" do
    ex_ast = quote do
      def something(one) when is_number(one) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
             return     Elixir.ElixirScript.Kernel.__load(Elixir).is_number(one);
           }));
    """

    assert_translation(ex_ast, js_code)


    ex_ast = quote do
      def something(one) when is_number(one) or is_atom(one) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
             return Elixir.ElixirScript.Kernel.__load(Elixir).is_number(one) || Elixir.ElixirScript.Kernel.__load(Elixir).is_atom(one);
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defp something(one) when is_number(one) or is_atom(one) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
             return     Elixir.ElixirScript.Kernel.__load(Elixir).is_number(one) || Elixir.ElixirScript.Kernel.__load(Elixir).is_atom(one);
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defp something(one, two) when one in [1, 2, 3] do
      end
    end


    js_code = """
    const something = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(one,two)    {
      return null;
    },function(one,two)    {
    return Elixir.ElixirScript.Bootstrap.Functions.__load(Elixir).contains(one,Object.freeze([1, 2, 3]));
    }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defmodule Example do
        def something(one) when one in [1, 2, 3] do
        end

        def something(one) when is_number(one) or is_atom(one) do
        end
      end
    end

    js_code = """
         const something = __P.defmatch(__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
           return     Elixir.ElixirScript.Bootstrap.Functions.__load(Elixir).contains(one,Object.freeze([1, 2, 3]));
           }),__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
             return     Elixir.ElixirScript.Kernel.__load(Elixir).is_number(one) || Elixir.ElixirScript.Kernel.__load(Elixir).is_atom(one);
           }));
    """
    assert_translation(ex_ast, js_code)

  end

  test "pattern match function with literal" do
    ex_ast = quote do
      def something(1) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([1],function()    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with list" do
    ex_ast = quote do
      def something([apple | fruits]) do
      end
    end


    js_code = """
    const something = __P.defmatch(__P.clause([__P.headTail(__P.variable(),__P.variable())],function(apple,fruits)    {
    return     null;
    }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with multiple items in list" do
    ex_ast = quote do
      def something([apple, pear, banana]) do
      end
    end


    js_code = """
    const something = __P.defmatch(__P.clause([Object.freeze([__P.variable(), __P.variable(), __P.variable()])],function(apple,pear,banana)    {
       return     null;
     }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with tuple" do
    ex_ast = quote do
      def something({ apple , fruits }) do
      end
    end


    js_code = """
         const something = __P.defmatch(__P.clause([new Bootstrap.Core.Tuple(__P.variable(), __P.variable())], function(apple, fruits) {
             return null;
         }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with struct" do
    ex_ast = quote do
      defmodule AStruct do
        defstruct []
      end

      def something(%AStruct{}) do
      end
    end


    js_code = """
         const something = __P.defmatch(__P.clause([{
             [Symbol.for('__struct__')]: Symbol.for('Elixir.AStruct')
         }], function() {
             return null;
         }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with struct reference" do
    ex_ast = quote do
      defmodule AStruct do
        defstruct []
      end

      def something(%AStruct{} = a) do
      end

    end

    js_code = """
         const something = __P.defmatch(__P.clause([__P.capture({
             [Symbol.for('__struct__')]: Symbol.for('Elixir.AStruct')
         })], function(a) {
             return null;
         }));
    """
    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with map reference" do
    ex_ast = quote do
      def something(%{ which: 13 } = a) do
      end
    end

    js_code = """
     const something = __P.defmatch(__P.clause([__P.capture({
             [Symbol.for('which')]: 13
       })],function(a)    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with struct decontructed" do
    ex_ast = quote do
      defmodule AStruct do
        defstruct [:key, :key1]
      end

      def something(%AStruct{key: value, key1: 2}) do
      end
    end


    js_code = """
         const something = __P.defmatch(__P.clause([{
             [Symbol.for('__struct__')]: Symbol.for('Elixir.AStruct'),
             [Symbol.for('key')]: __P.variable(),
             [Symbol.for('key1')]: 2
         }], function(value) {
             return null;
         }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defmodule AStruct do
        defstruct [:key, :key1]
      end

      def something(%AStruct{key: value, key1: 2}) when is_number(value) do
      end
    end


    js_code = """
         const something = __P.defmatch(__P.clause([{
             [Symbol.for('__struct__')]: Symbol.for('Elixir.AStruct'),
             [Symbol.for('key')]: __P.variable(),
             [Symbol.for('key1')]: 2
         }], function(value) {
             return null;
         }, function(value) {
             return Elixir.ElixirScript.Kernel.__load(Elixir).is_number(value);
         }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "pattern match function with binary part" do
    ex_ast = quote do
      def something("Bearer " <> token) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.startsWith('Bearer ')],function(token)    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def something("Bearer " <> token, hotel) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.startsWith('Bearer '), __P.variable()],function(token,hotel)    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def something("Bearer " <> token, hotel, 1) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.startsWith('Bearer '), __P.variable(), 1],function(token,hotel)    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "combine pattern matched functions of same arity" do
    ex_ast = quote do
      defmodule Example do
        def something(1) do
        end

        def something(2) do
        end

        def something(one) when is_binary(one) do
        end

        def something(one) do
        end
      end

    end


    js_code = """
         const something = __P.defmatch(__P.clause([1],function()    {
             return     null;
           }),__P.clause([2],function()    {
             return     null;
           }),__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
             return     Elixir.ElixirScript.Kernel.__load(Elixir).is_binary(one);
           }),__P.clause([__P.variable()],function(one)    {
             return     null;
           }));
    """

    assert_translation(ex_ast, js_code)

  end

  test "translate varible declaration correctly" do
    ex_ast = quote do
      def test1(alpha, beta) do
        a = 1
        a = 2
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha,beta)    {
             let [a] = __P.match(__P.variable(),1);
             let [a1] = __P.match(__P.variable(),2);
             return     a1;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
        a = 1
        a = a
        a = 2
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha,beta)    {
             let [a] = __P.match(__P.variable(),1);
             let [a1] = __P.match(__P.variable(),a);
             let [a2] = __P.match(__P.variable(),2);
             return     a2;
           }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha, beta) do
        a = 1
        [a, b, c] = [a, 2, 3]
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha,beta)    {
         let [a] = __P.match(__P.variable(),1);
         let [a1,b,c] = __P.match(Object.freeze([__P.variable(), __P.variable(), __P.variable()]),Object.freeze([a, 2, 3]));
         let _ref = Object.freeze([a1, b, c]);
         return     _ref;
       }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate function variables with ? or !" do
    ex_ast = quote do
      def test1(alpha?, beta!) do
        a? = 1
        b! = 2
      end
    end

    js_code = """
     const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable()],function(alpha__qmark__,beta__emark__)    {
             let [a__qmark__] = __P.match(__P.variable(),1);
             let [b__emark__] = __P.match(__P.variable(),2);
             return     b__emark__;
           }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate function params with defaults" do
    ex_ast = quote do
      def test1(alpha, beta \\ 0) do
      end
    end

    js_code = """
    const test1 = __P.defmatch(__P.clause([__P.variable(), __P.variable(0)],function(alpha,beta)    {
      return     null;
    }));
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      def test1(alpha \\ fn x -> x end) do
      end
    end

    js_code = """
    const test1 = __P.defmatch(__P.clause([__P.variable(__P.defmatch(__P.clause([__P.variable()],function(x)    {
      return     x;
    })))],
    function(alpha)    {
      return     null;
    }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "def with catch" do
    ex_ast = quote do
      defp func(param) do
        if true do
          nil
        else
          :error
        end
      catch
        :invalid -> :error
      end
    end

    js_code = """
    const func = __P.defmatch(__P.clause([__P.variable()],
    function(param) {
      return Bootstrap.Core.SpecialForms._try(function() {
        return __P.defmatch(__P.clause([__P.variable()], function(x) {
          return Symbol.for('error');
        },
        function(x) {
        return x === null || x === false;
        }),
        __P.clause([__P.variable()], function(__ignored__) {
            return null;
        })).call(this, true);
      },
      null,
      __P.defmatch(__P.clause([Symbol.for('invalid')], function() {
        return Symbol.for('error');
      })),
      null,
      null
     );
    }));
    """

    assert_translation(ex_ast, js_code)
  end


  test "translate anonymous function with variable bound" do
    ex_ast = quote do
      key = "test"
      fn ^key -> :ok end
    end

    js_code = """
    let [key] = __P.match(__P.variable(),'test');

    __P.defmatch(
      __P.clause(
        [__P.bound(key)],
        function() {
          return Symbol.for('ok');
        }
      )
    )
    """

    assert_translation(ex_ast, js_code)
  end

  test "multiple when guards" do
    ex_ast = quote do
      def something(one) when is_number(one) when is_atom(one) do
      end
    end


    js_code = """
     const something = __P.defmatch(__P.clause([__P.variable()],function(one)    {
             return     null;
           },function(one)    {
             return Elixir.ElixirScript.Kernel.__load(Elixir).is_number(one) || Elixir.ElixirScript.Kernel.__load(Elixir).is_atom(one);
           }));
    """

    assert_translation(ex_ast, js_code)
  end
end
