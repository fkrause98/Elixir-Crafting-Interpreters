defmodule InterpretersTest.Parser do
  defmodule Decimals do
    use ExUnit.Case
    import ExUnit.CaptureIO

    test "Decimal parser -- single integer" do
      input = "1234"
      assert {:ok, [1234], "", %{}, {1, 0}, 4} = Scanner.Parser.decimal(input)
    end

    test "Decimal parser -- single integer & remainder" do
      input = "1234 5132"
      assert {:ok, [1234], " 5132", %{}, {1, 0}, 4} = Scanner.Parser.decimal(input)
    end

    test "Decimal parser -- single integer plus dot fails" do
      input = "1234."
      assert {:error, _, _, _, _, _} = Scanner.Parser.decimal(input)
    end

    test "Decimal parser -- integer & decimal part" do
      input = "1234.5678910"

      assert {:ok, [1234, ".", 5_678_910], "", %{}, {1, 0}, 12} =
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
  end
end
