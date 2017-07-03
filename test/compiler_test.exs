defmodule ElixirScript.Compiler.Test do
  use ExUnit.Case

  test "Can compile one entry module" do
    result = ElixirScript.Compiler.compile(Version)
    assert is_binary(result)
  end

  test "Can compile multiple entry modules" do
    result = ElixirScript.Compiler.compile([Atom, String])
    assert is_binary(result)
  end

  test "Error on unknown module" do
    assert_raise ElixirScript.CompileError, fn ->
      ElixirScript.Compiler.compile(SomeModule)
    end
  end

  test "Output format: es" do
    result = ElixirScript.Compiler.compile(Atom, [format: :es, js_modules: [{React, "react"}, {ReactDOM, "react-dom", default: false}]])
    assert result =~ "export default Elixir"
  end

  test "Output format: umd" do
    result = ElixirScript.Compiler.compile(Atom, [format: :umd, js_modules: [{React, "react"}]])
    assert result =~ "factory"
  end

  test "Output format: common" do
    result = ElixirScript.Compiler.compile(Atom, [format: :common, js_modules: [{React, "react"}]])
    assert result =~ "module.exports = Elixir"
  end

  test "Output file with default name" do
    path = System.tmp_dir()

    result = ElixirScript.Compiler.compile(Atom, [output: path])
    assert File.exists?(Path.join([path, "Elixir.App.js"]))
  end

  test "Output file with custom name" do
    path = System.tmp_dir()
    path = Path.join([path, "myfile.js"])

    result = ElixirScript.Compiler.compile(Atom, [output: path])
    assert File.exists?(path)
  end

  test "Compiles module functions correctly" do
    bootstrap = ElixirScript.Compiler.compile(TestModuleB, [format: :common])
    code = """
      #{bootstrap};
      Elixir.start(Elixir.TestModuleB, [(ret) => {
        console.log(JSON.stringify(ret))
      }])
    """
    bootstrap = ElixirScript.Compiler.compile(TestModuleB, [format: :umd])
    html = """
      <html>
        <head>
          <script>#{bootstrap}</script>
          <script></script>
        </head>
      </html>
    """
    File.write "./tmp/compiled.html", html
    {out, _} = System.cmd "node", ["-e", code]
    val = Poison.decode! String.trim out
    assert val == [1, 2, 3]
  end
end 