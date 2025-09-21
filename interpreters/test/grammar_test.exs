defmodule InterpretersTest.Grammar do
  use ExUnit.Case
  alias Grammar.Traverse.ASTRepr

  test "Raw input -> tokens -> binary op" do
    input = "1+2"
    assert {:ok, [token_one, %Token{type: :plus}, token_two]} = Scanner.tokenize_source(input)

    assert {:ok, literal_one} = Grammar.Literal.from_token(token_one)
    assert {:ok, literal_two} = Grammar.Literal.from_token(token_two)

    assert "(+ 1.0 2.0)" ==
             %Grammar.BinaryOp{l_expr: literal_one, op: :plus, r_expr: literal_two}
             |> ASTRepr.repr()
  end

  test "Raw input 2 -> tokens -> binary op" do
    input = "(1+2)"

    assert {:ok, [%Token{type: :left_paren}, one, plus, two, %Token{type: :right_paren}]} =
             Scanner.tokenize_source(input)

    assert {:ok, literal_one} = Grammar.Literal.from_token(one)
    assert {:ok, literal_two} = Grammar.Literal.from_token(two)

    binary_op =
      %Grammar.BinaryOp{l_expr: literal_one, op: plus.type, r_expr: literal_two}

    assert "(group (+ 1.0 2.0))" = %Grammar.Grouping{expr: binary_op} |> ASTRepr.repr()
  end
end
