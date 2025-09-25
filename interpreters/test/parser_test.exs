defmodule InterpretersTest.Grammar do
  use ExUnit.Case

  defp parse_expression(source) do
    {:ok, tokens} = Scanner.tokenize_source(source)
    Parser.expression(tokens)
  end

  test "Parse simple literal (float)" do
    assert {:ok, tokens} = "1" |> Scanner.tokenize_source()
    assert {:ok, {_remainder, %Grammar.Primary{value: 1.0}}} = Parser.primary(tokens)
  end

  test "Parse simple literal (string)" do
    assert {:ok, tokens} =
             ~S("Hello, World") |> Scanner.tokenize_source()

    assert {:ok, {_remainder, %Grammar.Primary{value: "Hello, World"}}} = Parser.primary(tokens)
  end

  test "Parse simple literal (true)" do
    assert {:ok, tokens} = ~S(true) |> Scanner.tokenize_source()
    assert {:ok, {_remainder, %Grammar.Primary{value: true}}} = Parser.primary(tokens)
  end

  test "Parse simple literal (false)" do
    assert {:ok, tokens} = ~S(false) |> Scanner.tokenize_source()
    assert {:ok, {_remainder, %Grammar.Primary{value: false}}} = Parser.primary(tokens)
  end

  test "Parse simple literal (nil)" do
    assert {:ok, tokens} = ~S(nil) |> Scanner.tokenize_source()
    assert {:ok, {_remainder, %Grammar.Primary{value: nil}}} = Parser.primary(tokens)
  end

  test "Parse simple expression" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 == 2))
  end

  test "Parse equal with numbers expression" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 == 2))
  end

  test "Parse noneq numbers comparisons" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :bang_equal,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 != 2))
  end

  test "Parse gt numbers comparisons" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :greater,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 > 2))
  end

  test "Parse ge numbers comparisons" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :less_equal,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 <= 2))

    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :less_equal,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 <= 2))
  end

  test "Parse lt numbers comparisons" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :less,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression(~S(1 < 2))
  end

  test "Multiple comparisons " do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Binary{
                 l_expr: %Grammar.Primary{value: 1.0},
                 operator: :less,
                 r_expr: %Grammar.Primary{value: 2.0}
               },
               r_expr: %Grammar.Binary{
                 l_expr: %Grammar.Primary{value: 1.0},
                 operator: :greater,
                 r_expr: %Grammar.Primary{value: 2.0}
               }
             }}} = parse_expression(~S(1 < 2 == 1 > 2))
  end

  test "Parse equal with strings expression" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Primary{value: "World"},
               r_expr: %Grammar.Primary{value: "Hello"}
             }}} = parse_expression(~S("World" == "Hello"))
  end

  test "Parse number literal" do
    assert {:ok, {[], %Grammar.Primary{value: 42.0}}} = parse_expression("42")
  end

  test "Parse string literal" do
    assert {:ok, {[], %Grammar.Primary{value: "hello"}}} = parse_expression(~S("hello"))
  end

  test "Parse boolean literals" do
    assert {:ok, {[], %Grammar.Primary{value: true}}} = parse_expression("true")
    assert {:ok, {[], %Grammar.Primary{value: false}}} = parse_expression("false")
  end

  test "Parse nil literal" do
    assert {:ok, {[], %Grammar.Primary{value: nil}}} = parse_expression("nil")
  end

  test "Parse unary minus" do
    assert {:ok,
            {[],
             %Grammar.Unary{
               operator: :minus,
               expr: %Grammar.Primary{value: 5.0}
             }}} = parse_expression("-5")
  end

  test "Parse unary bang (not)" do
    assert {:ok,
            {[],
             %Grammar.Unary{
               operator: :bang,
               expr: %Grammar.Primary{value: true}
             }}} = parse_expression("!true")
  end

  test "Parse nested unary expressions" do
    assert {:ok,
            {[],
             %Grammar.Unary{
               operator: :minus,
               expr: %Grammar.Unary{
                 operator: :bang,
                 expr: %Grammar.Primary{value: false}
               }
             }}} = parse_expression("-!false")
  end

  test "Parse multiplication" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :star,
               l_expr: %Grammar.Primary{value: 3.0},
               r_expr: %Grammar.Primary{value: 4.0}
             }}} = parse_expression("3 * 4")
  end

  test "Parse division" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :slash,
               l_expr: %Grammar.Primary{value: 8.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression("8 / 2")
  end

  test "Parse chained multiplication (left associative)" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :star,
               l_expr: %Grammar.Binary{
                 operator: :star,
                 l_expr: %Grammar.Primary{value: 2.0},
                 r_expr: %Grammar.Primary{value: 3.0}
               },
               r_expr: %Grammar.Primary{value: 4.0}
             }}} = parse_expression("2 * 3 * 4")
  end

  test "Parse addition" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :plus,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression("1 + 2")
  end

  test "Parse subtraction" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :minus,
               l_expr: %Grammar.Primary{value: 10.0},
               r_expr: %Grammar.Primary{value: 3.0}
             }}} = parse_expression("10 - 3")
  end

  test "Parse chained addition (left associative)" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :plus,
               l_expr: %Grammar.Binary{
                 operator: :plus,
                 l_expr: %Grammar.Primary{value: 1.0},
                 r_expr: %Grammar.Primary{value: 2.0}
               },
               r_expr: %Grammar.Primary{value: 3.0}
             }}} = parse_expression("1 + 2 + 3")
  end

  # Comparison expressions
  test "Parse less than" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :less,
               l_expr: %Grammar.Primary{value: 5.0},
               r_expr: %Grammar.Primary{value: 10.0}
             }}} = parse_expression("5 < 10")
  end

  test "Parse greater than" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :greater,
               l_expr: %Grammar.Primary{value: 15.0},
               r_expr: %Grammar.Primary{value: 7.0}
             }}} = parse_expression("15 > 7")
  end

  test "Parse less than or equal" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :less_equal,
               l_expr: %Grammar.Primary{value: 3.0},
               r_expr: %Grammar.Primary{value: 3.0}
             }}} = parse_expression("3 <= 3")
  end

  test "Parse greater than or equal" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :greater_equal,
               l_expr: %Grammar.Primary{value: 8.0},
               r_expr: %Grammar.Primary{value: 5.0}
             }}} = parse_expression("8 >= 5")
  end

  # Equality expressions
  test "Parse equality" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 1.0}
             }}} = parse_expression("1 == 1")
  end

  test "Parse inequality" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :bang_equal,
               l_expr: %Grammar.Primary{value: 5.0},
               r_expr: %Grammar.Primary{value: 3.0}
             }}} = parse_expression("5 != 3")
  end

  # Operator precedence tests
  test "Parse arithmetic with precedence (multiplication before addition)" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :plus,
               l_expr: %Grammar.Primary{value: 2.0},
               r_expr: %Grammar.Binary{
                 operator: :star,
                 l_expr: %Grammar.Primary{value: 3.0},
                 r_expr: %Grammar.Primary{value: 4.0}
               }
             }}} = parse_expression("2 + 3 * 4")
  end

  test "Parse comparison with arithmetic (arithmetic has higher precedence)" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :less,
               l_expr: %Grammar.Binary{
                 operator: :plus,
                 l_expr: %Grammar.Primary{value: 1.0},
                 r_expr: %Grammar.Primary{value: 2.0}
               },
               r_expr: %Grammar.Binary{
                 operator: :star,
                 l_expr: %Grammar.Primary{value: 3.0},
                 r_expr: %Grammar.Primary{value: 4.0}
               }
             }}} = parse_expression("1 + 2 < 3 * 4")
  end

  test "Parse equality with comparison (comparison has higher precedence)" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Binary{
                 operator: :less,
                 l_expr: %Grammar.Primary{value: 1.0},
                 r_expr: %Grammar.Primary{value: 2.0}
               },
               r_expr: %Grammar.Binary{
                 operator: :greater,
                 l_expr: %Grammar.Primary{value: 3.0},
                 r_expr: %Grammar.Primary{value: 4.0}
               }
             }}} = parse_expression("1 < 2 == 3 > 4")
  end

  # Complex expressions
  test "Parse complex arithmetic expression" do
    # 2 + 3 * 4 - 5 / 2
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :minus,
               l_expr: %Grammar.Binary{
                 operator: :plus,
                 l_expr: %Grammar.Primary{value: 2.0},
                 r_expr: %Grammar.Binary{
                   operator: :star,
                   l_expr: %Grammar.Primary{value: 3.0},
                   r_expr: %Grammar.Primary{value: 4.0}
                 }
               },
               r_expr: %Grammar.Binary{
                 operator: :slash,
                 l_expr: %Grammar.Primary{value: 5.0},
                 r_expr: %Grammar.Primary{value: 2.0}
               }
             }}} = parse_expression("2 + 3 * 4 - 5 / 2")
  end

  test "Parse expression with unary and binary operators" do
    # -5 + 3
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :plus,
               l_expr: %Grammar.Unary{
                 operator: :minus,
                 expr: %Grammar.Primary{value: 5.0}
               },
               r_expr: %Grammar.Primary{value: 3.0}
             }}} = parse_expression("-5 + 3")
  end

  test "Parse complex boolean expression" do
    # !true == false
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Unary{
                 operator: :bang,
                 expr: %Grammar.Primary{value: true}
               },
               r_expr: %Grammar.Primary{value: false}
             }}} = parse_expression("!true == false")
  end

  # Edge cases and error conditions
  test "Parse single token expressions" do
    assert {:ok, {[], %Grammar.Primary{value: 123.0}}} = parse_expression("123")
    assert {:ok, {[], %Grammar.Primary{value: "test"}}} = parse_expression(~S("test"))
  end

  test "Parse expression with whitespace" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :plus,
               l_expr: %Grammar.Primary{value: 1.0},
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression("  1   +   2  ")
  end

  # Associativity tests
  test "Parse left-associative subtraction" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :minus,
               l_expr: %Grammar.Binary{
                 operator: :minus,
                 l_expr: %Grammar.Primary{value: 10.0},
                 r_expr: %Grammar.Primary{value: 5.0}
               },
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression("10 - 5 - 2")
  end

  test "Parse left-associative division" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :slash,
               l_expr: %Grammar.Binary{
                 operator: :slash,
                 l_expr: %Grammar.Primary{value: 20.0},
                 r_expr: %Grammar.Primary{value: 4.0}
               },
               r_expr: %Grammar.Primary{value: 2.0}
             }}} = parse_expression("20 / 4 / 2")
  end

  # Mixed type expressions
  test "Parse mixed type comparisons" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :equal_equal,
               l_expr: %Grammar.Primary{value: "hello"},
               r_expr: %Grammar.Primary{value: "world"}
             }}} = parse_expression(~S("hello" == "world"))
  end

  test "Parse nil comparisons" do
    assert {:ok,
            {[],
             %Grammar.Binary{
               operator: :bang_equal,
               l_expr: %Grammar.Primary{value: nil},
               r_expr: %Grammar.Primary{value: 5.0}
             }}} = parse_expression("nil != 5")
  end
end
