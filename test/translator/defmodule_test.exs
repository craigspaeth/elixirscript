defmodule ElixirScript.Translator.Defmodule.Test do
  use ExUnit.Case
  import ElixirScript.TestHelper

  test "translate empty module" do
    ex_ast = quote do
      defmodule Elephant do
      end
    end

    js_code = """
    const __exports = {
        __info__
    };
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate defmodules" do
    ex_ast = quote do
      defmodule Elephant do
        require JS
        @ul "#todo-list"

        def something() do
          @ul
        end

        JS.defgenp something_else() do
        end
      end
    end

    js_code = """
         const something = __P.defmatch(__P.clause([], function() {
             return ul;
         }));

         const __info__ = function(kind) {
                 return __P.defmatch(__P.clause([Symbol.for('functions')], function() {
                     return Object.freeze([new Bootstrap.Core.Tuple(Symbol.for('something'), 0)]);
                 }), __P.clause([Symbol.for('macros')], function() {
                     return Object.freeze([]);
                 }), __P.clause([Symbol.for('module')], function() {
                     return Symbol.for('Elixir.Elephant');
                 })).call(this, kind);
             };

         const ul = '#todo-list';

         const something_else = __P.defmatchgen(__P.clause([], function*() {
             return null;
         }));
    """

    assert_translation(ex_ast, js_code)
  end

  test "translate modules with inner modules" do
    ex_ast = quote do
      defmodule Animals do

        defmodule Elephant do
          defstruct [trunk: true]
        end

        def something() do
          %Animals.Elephant{}
        end

        defp something_else() do
        end

      end
    end

    js_code = """
    const __struct__ = function(values = {}) {
        const allowed_keys = [Symbol.for('trunk')]

        const value_keys = Object.keys(values)

        const every_call_result = value_keys.every(function(key) {
            return allowed_keys.includes(key);
        })

        if (every_call_result) {
            return Object.assign({}, {
                [Symbol.for('__struct__')]: Symbol.for('Elixir.Animals.Elephant'),
                [Symbol.for('trunk')]: true
            }, values);
        } else {
            throw 'Unallowed key found';
        }
    };
    """

    assert_translation(ex_ast, js_code)
  end


  test "translate modules with inner module that has inner module" do
    ex_ast = quote do
      defmodule Animals do

        defmodule Elephant do
          defstruct trunk: true

          defmodule Bear do
            defstruct trunk: true
          end
        end


        def something() do
          %Animals.Elephant{}
        end

        defp something_else() do
        end

      end
    end

    js_code = """
         const __struct__ = function(values = {}) {
                 const allowed_keys = [Symbol.for('trunk')]

                 const value_keys = Object.keys(values)

                 const every_call_result = value_keys.every(function(key) {
                     return allowed_keys.includes(key);
                 })

                 if (every_call_result) {
                     return Object.assign({}, {
                         [Symbol.for('__struct__')]: Symbol.for('Elixir.Animals.Elephant.Bear'),
                         [Symbol.for('trunk')]: true
                     }, values);
                 } else {
                     throw 'Unallowed key found';
                 }
             };
    """

    assert_translation(ex_ast, js_code)
  end

  test "Pull out module references and make them into imports if modules listed" do
    ex_ast = quote do
      defmodule Lions.Tigers.Bears do
        def oh_my() do
        end
      end

      defmodule Lions.Tigers do
        def oh_my() do
        end

        Lions.Tigers.Bears.oh_my()
      end

      defmodule Animals do
        Lions.Tigers.oh_my()
      end
    end

    js_code = """
    Elixir.Lions.Tigers.Bears.__load(Elixir).oh_my()
    """

    assert_translation(ex_ast, js_code)
  end

end
