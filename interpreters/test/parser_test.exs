defmodule InterpretersTest.Parser do
  defmodule Decimals do
    use ExUnit.Case
    import ExUnit.CaptureIO

    test "Decimal parser -- single integer" do
      input = "1234"
      assert {:ok, [1234.0], "", %{}, {1, 0}, 4} = Scanner.Parser.decimal(input)
    end

    test "Decimal parser -- single integer & remainder" do
      input = "1234 5132"
      assert {:ok, [1234.0], " 5132", %{}, {1, 0}, 4} = Scanner.Parser.decimal(input)
    end

    test "Decimal parser -- single integer plus dot fails" do
      input = "1234."
      assert {:error, _, _, _, _, _} = Scanner.Parser.decimal(input)
    end

    test "Decimal parser -- integer & decimal part" do
      input = "1234.5678910"

      assert {:ok, [1234.5_678_910], "", %{}, {1, 0}, 12} =
               Scanner.Parser.decimal(input)
    end
  end

  defmodule SingleCharacter do
    use ExUnit.Case
    import ExUnit.CaptureIO

    test "Token parser -- single token" do
      input = ["(", ")", "{", "}", ",", ".", "-", "+", ";", "*"]

      for token <- input do
        assert {:ok, [token], "", %{}, {1, 0}, 1} = Scanner.Parser.token(token)
      end
    end

    test "Token parser -- operator" do
      input = ["!", "=", "<", ">"]

      for token <- input do
        assert {:ok, [token], "", %{}, _, _} = Scanner.Parser.operator(token)
      end
    end

    test "Token parser -- two token operator" do
      input = ["!=", "==", "<=", ">="]

      for token <- input do
        assert {:ok, [token], "", %{}, _, _} = Scanner.Parser.operator(token)
      end
    end
  end

  defmodule LiteralString do
    use ExUnit.Case
    import ExUnit.CaptureIO

    test "Token parser -- literal empty string" do
      input = ~S("")
      assert {:ok, [~S("")], "", %{}, _, _} = Scanner.Parser.literal_string(input)
    end

    test "Token parser -- literal non empty string" do
      input = ~S("I will make him an offer he can't refuse")

      assert {:ok, [~S("I will make him an offer he can't refuse")], "", %{}, _, _} =
               Scanner.Parser.literal_string(input)
    end

    test "Token parser -- literal multiline string" do
      input =
        "\"But let me say this. \n
      I am a superstitious man, a ridiculous failing but I must confess it here. \n
      And so if some unlucky accident should befall my youngest son, if some police officer should accidentally shoot him, if he should \n \n
      hang himself while in his jail cell, if new witnesses appear to testify to his guilt, my superstition will make me \n
      feel that it was the result of the ill will still borne me by some people here. \n
      Let me go further. If my son is struck by a bolt of lightning I will blame some of the people here. \n
      If his plane show fall into the sea or his ship sink beneath the waves of the ocean, if he should catch a mortal fever, if his automobile should be struck by a train, such is my superstition that I would blame the ill will felt by people here. \n
      Gentlemen, that ill will, that bad luck, I could never forgive. \n
      But aside from that let me swear by the souls of my grandchildren that I will never break the peace we have made. \n
      After all, are we or are we not better men than those pezzonovanti who have killed countless millions of men in our lifetimes?\n \""

      assert {:ok, [^input], "", %{}, _, _} =
               Scanner.Parser.literal_string(input)
    end
  end

  defmodule LoxSyntax.SingleToken do
    use ExUnit.Case
    import ExUnit.CaptureIO

    test "Lox Syntax -- Single Token -- Maps to correct type" do
      simple_values = [
        {"(", %Token{type: :left_paren, lexeme: "(", literal: nil, line: 1}},
        {")", %Token{type: :right_paren, lexeme: ")", literal: nil, line: 1}},
        {"{", %Token{type: :left_brace, lexeme: "{", literal: nil, line: 1}},
        {"}", %Token{type: :right_brace, lexeme: "}", literal: nil, line: 1}},
        {",", %Token{type: :comma, lexeme: ",", literal: nil, line: 1}},
        {".", %Token{type: :dot, lexeme: ".", literal: nil, line: 1}},
        {"-", %Token{type: :minus, lexeme: "-", literal: nil, line: 1}},
        {"+", %Token{type: :plus, lexeme: "+", literal: nil, line: 1}},
        {";", %Token{type: :semicolon, lexeme: ";", literal: nil, line: 1}},
        {"*", %Token{type: :star, lexeme: "*", literal: nil, line: 1}}
      ]

      for {token, expected} <- simple_values do
        assert {:ok, [^expected], "", %{}, {1, 0}, 1} = Scanner.Parser.lox_syntax(token)
      end
    end

    test "Lox Syntax -- Two single tokens" do
      input = "()"
      expected_1 = %Token{type: :left_paren, lexeme: "(", literal: nil, line: 1}
      expected_2 = %Token{type: :right_paren, lexeme: ")", literal: nil, line: 1}

      parsing_result = Scanner.Parser.lox_syntax(input)

      assert {:ok, [^expected_1, ^expected_2], "", %{}, _, _} = Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Numbers mixed with tokens and whitespace" do
      input = "(   1.23   ) "
      expected_1 = %Token{type: :left_paren, lexeme: "(", literal: nil, line: 1}
      expected_2 = %Token{type: :number, lexeme: nil, literal: 1.23, line: 1}
      expected_3 = %Token{type: :right_paren, lexeme: ")", literal: nil, line: 1}

      parsing_result = Scanner.Parser.lox_syntax(input)

      assert {:ok, [^expected_1, ^expected_2, ^expected_3], "", %{}, _, _} =
               Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Numbers mixed with tokens and strings" do
      input = "(  1.23 )" <> ~S("A string")
      expected_1 = %Token{type: :left_paren, lexeme: "(", literal: nil, line: 1}
      expected_2 = %Token{type: :number, lexeme: nil, literal: 1.23, line: 1}
      expected_3 = %Token{type: :right_paren, lexeme: ")", literal: nil, line: 1}
      expected_4 = %Token{type: :string, lexeme: nil, literal: "A string", line: 1}

      parsing_result = Scanner.Parser.lox_syntax(input)

      assert {:ok, [^expected_1, ^expected_2, ^expected_3, ^expected_4], "", %{}, _, _} =
               Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Double token operators" do
      double_token_operators = [
        {"!=", %Token{type: :bang_equal, lexeme: "!=", literal: nil, line: 1}},
        {"==", %Token{type: :equal_equal, lexeme: "==", literal: nil, line: 1}},
        {"<=", %Token{type: :less_equal, lexeme: "<=", literal: nil, line: 1}},
        {">=", %Token{type: :greater_equal, lexeme: ">=", literal: nil, line: 1}}
      ]

      for {operator, expected} <- double_token_operators do
        assert {:ok, [^expected], "", %{}, {1, 0}, 2} = Scanner.Parser.lox_syntax(operator)
      end
    end

    test "Lox Syntax -- Double token operators with whitespace" do
      input = "  !=  "
      expected = %Token{type: :bang_equal, lexeme: "!=", literal: nil, line: 1}

      assert {:ok, [^expected], "", %{}, _, _} = Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Double token operators mixed with parentheses" do
      input = "(!=)"
      expected_1 = %Token{type: :left_paren, lexeme: "(", literal: nil, line: 1}
      expected_2 = %Token{type: :bang_equal, lexeme: "!=", literal: nil, line: 1}
      expected_3 = %Token{type: :right_paren, lexeme: ")", literal: nil, line: 1}

      assert {:ok, [^expected_1, ^expected_2, ^expected_3], "", %{}, _, _} =
               Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Double token operators with numbers" do
      input = "1.23 != 4.56"
      expected_1 = %Token{type: :number, lexeme: nil, literal: 1.23, line: 1}
      expected_2 = %Token{type: :bang_equal, lexeme: "!=", literal: nil, line: 1}
      expected_3 = %Token{type: :number, lexeme: nil, literal: 4.56, line: 1}

      assert {:ok, [^expected_1, ^expected_2, ^expected_3], "", %{}, _, _} =
               Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Double token operators with strings" do
      input = ~S("hello" == "world")
      expected_1 = %Token{type: :string, lexeme: nil, literal: "hello", line: 1}
      expected_2 = %Token{type: :equal_equal, lexeme: "==", literal: nil, line: 1}
      expected_3 = %Token{type: :string, lexeme: nil, literal: "world", line: 1}

      assert {:ok, [^expected_1, ^expected_2, ^expected_3], "", %{}, _, _} =
               Scanner.Parser.lox_syntax(input)
    end

    test "Lox Syntax -- Single vs double token disambiguation" do
      input = "!="
      expected = %Token{type: :bang_equal, lexeme: "!=", literal: nil, line: 1}

      assert {:ok, [^expected], "", %{}, _, _} = Scanner.Parser.lox_syntax(input)

      input_spaced = "! ="
      expected_1 = %Token{type: :bang, lexeme: "!", literal: nil, line: 1}
      expected_2 = %Token{type: :equal, lexeme: "=", literal: nil, line: 1}

      assert {:ok, [^expected_1, ^expected_2], "", %{}, _, _} =
               Scanner.Parser.lox_syntax(input_spaced)
    end

    test "Lox Syntax -- Single token operators" do
      single_token_operators = [
        {"!", %Token{type: :bang, lexeme: "!", literal: nil, line: 1}},
        {"=", %Token{type: :equal, lexeme: "=", literal: nil, line: 1}},
        {"<", %Token{type: :less, lexeme: "<", literal: nil, line: 1}},
        {">", %Token{type: :greater, lexeme: ">", literal: nil, line: 1}}
      ]

      for {operator, expected} <- single_token_operators do
        assert {:ok, [^expected], "", %{}, {1, 0}, 1} = Scanner.Parser.lox_syntax(operator)
      end
    end

    test "Lox Syntax -- Single token operators with whitespace" do
      input = "  !  "
      expected = %Token{type: :bang, lexeme: "!", literal: nil, line: 1}

      assert {:ok, [^expected], "", %{}, _, _} = Scanner.Parser.lox_syntax(input)
    end

    test "Error collection -- Unknown single character" do
      input = "@"

      assert {:ok, [], "", context, {1, 0}, 1} = Scanner.Parser.lox_syntax(input)
      errors = Map.get(context, :errors, [])
      assert length(errors) == 1
      assert hd(errors) =~ "Unknown character in line 1: @"
    end

    test "Error collection -- Unknown character in known tokens" do
      input = "(@ )"

      assert {:ok, tokens, rest, context, line_info, offset} = Scanner.Parser.lox_syntax(input)
      errors = Map.get(context, :errors, [])

      token_types = Enum.map(tokens, & &1.type)
      assert :left_paren in token_types
      assert :right_paren in token_types
    end
  end
end
