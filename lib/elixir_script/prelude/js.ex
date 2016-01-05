defmodule ElixirScript.JS do

  @doc """
  Creates new JavaScript objects.

  ex:
    JS.new User, ["first_name", "last_name"]
  """
  defmacro new(module, params) do
  end


  @doc """
  Updates an existing JavaScript object.

  ex:
    JS.update elem, "width", 100
  """
  defmacro update(object, property, value) do
  end


  @doc """
  Imports a JavaScript module.

  Elixir modules can use the normal `import`, `alias` and `require`,
  but JavaScript modules work differently and have to be imported
  using this.

  If module is not a list, then it is treated as a default import,
  otherwise it is not.

  ex:
    JS.import A, "a" #translates to "import A from 'a'"

    JS.import [A, B, C], "a" #translates to "import {A, B, C} from 'a'"
  """
  defmacro import(module, from) do
  end


  @doc """
  Imports a JavaScript module.

  Works like import/2, but tries to infer the path to the module.
  Only works for default imports. Uses `Macro.underscore` to infer path.

  ex:
    JS.import React #translates to "import React from 'react'"
  """
  defmacro import(module) do
  end


  @doc """
  Returns a reference to the global object.

  In browsers this would be Window or WindowProxy.
  In node this would be the global object.
  """
  def global() do
    Elixir.Core.Functions.get_global()
  end


  defmacro type_of(type) do
  end


end
