defmodule Scanner.Parser do
  import NimbleParsec
  single_integer = integer(min: 1) |> lookahead_not(string("."))
  integer_point_and_decimal = integer(min: 1) |> string(".") |> integer(min: 1)

  decimal_parser =
    choice([
      single_integer,
      integer_point_and_decimal
    ])

  defparsec(:decimal, decimal_parser)

  single_char_parser =
    choice([
      string("("),
      string(")"),
      string("{"),
      string("}"),
      string(","),
      string("."),
      string("-"),
      string("+"),
      string(";"),
      string("*")
    ])

  defparsec(:token, single_char_parser |> post_traverse({:map_token_to_type, []}))

  one_token_operator =
    choice([
      string("!"),
      string("="),
      string("<"),
      string(">")
    ])
    |> lookahead_not(string("="))

  two_token_operator =
    choice([
      string("!="),
      string("=="),
      string("<="),
      string(">=")
    ])

  operator = choice([one_token_operator, two_token_operator])

  defparsec(:operator, operator)

  escaped_char = ascii_char([?\\]) |> utf8_char([])
  string_char = choice([escaped_char, utf8_char([{:not, ?"}])])

  defparsec(
    :literal_string,
    ascii_char([?"])
    |> repeat(string_char)
    |> ascii_char([?"])
    |> reduce({List, :to_string, []})
  )

  defparsec(
    :lox_syntax,
    single_char_parser
    |> post_traverse({:map_token_to_type, []})
    # single_char_parser
  )

  defp map_token_to_type(rest, args = [char], context, {line, col}, offset)
       when is_binary(char) do
    token_type =
      cond do
        char == "(" -> :left_paren
        char == ")" -> :right_paren
        char == "{" -> :left_brace
        char == "}" -> :right_brace
        char == "," -> :comma
        char == "." -> :dot
        char == "-" -> :minus
        char == "+" -> :plus
        char == ";" -> :semicolon
        char == "*" -> :star
        # is_operator(char, following_chars) -> operator_type(char)
        true -> :unknown
      end

    token = %Token{
      type: token_type,
      lexeme: char,
      literal: nil,
      line: line
    }

    {rest, [token], context}
  end
end

defmodule Scanner.Helpers do
  def is_operator(leading_char, ["=" | _]), do: leading_char in ["!", "=", "<", ">"]
  def is_operator(_, _), do: false

  def operator_type(char) do
    case char do
      "!" -> :bang_equal
      "=" -> :equal_equal
      "<" -> :less_equal
      ">" -> :greater_equal
    end
  end

  def is_string("\""), do: true
  def is_string(_), do: false

  defguard is_digit(char) when char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
end

defmodule Scanner do
  import Scanner.Helpers
  @enforce_keys [:source, :chars, :tokens, :line, :start, :current]
  defstruct [:source, :chars, tokens: [], current: 0, line: 0, start: 0]

  def from_source(source) do
    %Scanner{
      source: source,
      chars: source_to_chars(source),
      tokens: [],
      current: 0,
      line: 0,
      start: 0
    }
  end

  defp source_to_chars(source) when is_binary(source) do
    source
    |> String.graphemes()
  end

  defp source_to_chars(_), do: raise("String expected")

  # Finish when there are no tokens left
  def scan_tokens(%Scanner{chars: [], tokens: tokens}), do: {:ok, tokens |> Enum.reverse()}

  # # FIXME: Implement comments
  # def scan_tokens(%Scanner{chars: ["/", "/" | _]}) do
  #   raise "Implement comments"
  # end

  # def scan_tokens(scanner = %Scanner{chars: [char | following_chars]})
  #     when char in [" ", "\r", "\t"] do
  #   scan_tokens(%Scanner{scanner | chars: following_chars})
  # end

  # def scan_tokens(scanner = %Scanner{chars: ["\n" | following_chars], line: line}) do
  #   scan_tokens(%Scanner{scanner | chars: following_chars, line: line + 1})
  # end

  def scan_tokens(scanner = %Scanner{source: source}) do
    # next_token_type =
    #   cond do
    #     char == "(" -> :left_paren
    #     char == ")" -> :right_paren
    #     char == "{" -> :left_brace
    #     char == "}" -> :right_brace
    #     char == "," -> :comma
    #     char == "." -> :dot
    #     char == "-" -> :minus
    #     char == "+" -> :plus
    #     char == ";" -> :semicolon
    #     char == "*" -> :star
    #     is_operator(char, following_chars) -> operator_type(char)
    #     true -> :unknown
    #   end

    # case next_token_type do
    #   :unknown ->
    #     Lox.error(scanner.line, "Unexpected token")

    # :number ->
    #   raise "Todo"

    # scanner.source
    # |> String.slice(scanner.start..scanner.current)
    # {:ok, [integer_part], remainder, %{}, _, _} =
    #   scanner.source
    #   |> String.slice(scanner.start(...))
    #   |> Scanner.Parser.Decimals.decimal()
    #   |> dbg

    # {literal, ""} = Float.parse("#{integer_part}")

    # %Token{
    #   type: :number,
    #   literal: literal,
    #   lexeme: nil,
    #   line: 0
    # }

    # :string ->
    #   string_scanning_result =
    #     scan_string(%Scanner{
    #       scanner
    #       | chars: following_chars,
    #         start: scanner.current,
    #         current: scanner.current + 1
    #     })

    #   case string_scanning_result do
    #     {:ok, updated_scanner} ->
    #       scan_tokens(updated_scanner)

    #     {:error, msg} ->
    #       Lox.error(scanner.line, msg)
    #   end

    # _ when next_token_type in [:bang_equal, :equal_equal, :less_equal, :greater_equal] ->
    #   scanner
    #   |> handle_operator(next_token_type)
    #   |> scan_tokens()

    # _ ->
    #   scanner
    #   |> handle_single_char_token(next_token_type)
    #   |> scan_tokens()
  end

  defp scan_string(scanner = %Scanner{chars: []}) do
    Lox.error(scanner.line, "Unfinished string")
  end

  defp scan_string(scanner = %Scanner{chars: [char | tail], line: line}) do
    case char do
      "\n" ->
        scan_string(%Scanner{scanner | chars: tail, line: line + 1})

      "\"" ->
        string_token = %Token{
          type: :string,
          lexeme: nil,
          line: scanner.line,
          literal: scanner.source |> String.slice(scanner.start..(scanner.current + 1))
        }

        {:ok,
         %Scanner{
           scanner
           | tokens: [string_token | scanner.tokens],
             chars: tail,
             current: scanner.current + 1,
             start: scanner.current
         }}

      _ ->
        scan_string(%Scanner{scanner | current: scanner.current + 1, chars: tail})
    end
  end

  defp handle_operator(scanner = %Scanner{chars: [_, "=" | following_chars]}, next_token_type) do
    next_token = %Token{
      type: next_token_type,
      literal: nil,
      lexeme:
        String.slice(
          scanner.source,
          scanner.start..(scanner.current + 2)
        ),
      line: scanner.line
    }

    %Scanner{
      scanner
      | chars: following_chars,
        tokens: [next_token | scanner.tokens],
        current: scanner.current + 2,
        start: scanner.current
    }
  end

  defp handle_single_char_token(scanner = %Scanner{chars: [_ | following_chars]}, next_token_type) do
    next_token = %Token{
      type: next_token_type,
      literal: nil,
      lexeme:
        String.slice(
          scanner.source,
          scanner.start..(scanner.current + 1)
        ),
      line: scanner.line
    }

    %Scanner{
      scanner
      | chars: following_chars,
        tokens: [next_token | scanner.tokens],
        current: scanner.current + 1,
        start: scanner.current
    }
  end
end
