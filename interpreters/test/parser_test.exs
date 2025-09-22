defmodule InterpretersTest.Grammar do
  use ExUnit.Case

  test "Parse simple literal (float)" do
    assert {:ok, tokens} = "1" |> Scanner.tokenize_source()
    assert {:ok, %Grammar.Primary{value: 1.0}} = Parser.primary(tokens)
  end

  test "Parse simple literal (string)" do
    assert {:ok, tokens} =
             ~S("Hello, World") |> Scanner.tokenize_source()

    assert {:ok, %Grammar.Primary{value: "Hello, World"}} = Parser.primary(tokens)
  end

  test "Parse simple literal (true)" do
    assert {:ok, tokens} = ~S(true) |> Scanner.tokenize_source()
    assert {:ok, %Grammar.Primary{value: true}} = Parser.primary(tokens)
  end

  test "Parse simple literal (false)" do
    assert {:ok, tokens} = ~S(false) |> Scanner.tokenize_source()
    assert {:ok, %Grammar.Primary{value: false}} = Parser.primary(tokens)
  end

  test "Parse simple literal (nil)" do
    assert {:ok, tokens} = ~S(nil) |> Scanner.tokenize_source()
    assert {:ok, %Grammar.Primary{value: nil}} = Parser.primary(tokens)
  end
end
