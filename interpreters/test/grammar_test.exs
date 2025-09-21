defmodule InterpretersTest.Grammar do
  use ExUnit.Case
  alias Grammar.Traverse.ASTRepr

  test "Raw input -> tokens -> binary op" do
    input = "1+2"
    assert {:ok, [token_one, %Token{type: :plus}, token_two]} = Scanner.tokenize_source(input)

    assert {:ok, literal_one} = Grammar.Literal.from_token(token_one)
    assert {:ok, literal_two} = Grammar.Literal.from_token(token_two)

    assert "(+ 1.0 2.0 )" ==
             %Grammar.BinaryOp{l_expr: literal_one, op: :plus, r_expr: literal_two}
             |> ASTRepr.repr()
  end
end
