defmodule Scanner do
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

  defp source_to_chars(_), do: raise("String expecte")

  # Finish when there are no tokens left
  def scan_tokens(%Scanner{chars: [], tokens: tokens}), do: {:ok, tokens |> Enum.reverse()}

  # FIXME: Implement comments
  def scan_tokens(scanner = %Scanner{chars: ["/", "/" | _]}) do
    raise "Implement comments"
  end

  def scan_tokens(scanner = %Scanner{chars: [char | following_chars]})
      when char in [" ", "\r", "\t"] do
    scan_tokens(%Scanner{scanner | chars: following_chars})
  end

  def scan_tokens(scanner = %Scanner{chars: ["\n" | following_chars], line: line}) do
    scan_tokens(%Scanner{scanner | chars: following_chars, line: line + 1})
  end

  def scan_tokens(
        scanner = %Scanner{chars: [char | following_chars], start: start, current: current}
      ) do
    next_token_type =
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
        is_operator(char, following_chars) -> operator_type(char)
        is_string(char) -> :string
        true -> :unknown
      end

    case next_token_type do
      :unknown ->
        Lox.error(scanner.line, "Unexpected token")

      :string ->
        string_scanning_result =
          scan_string(%Scanner{
            scanner
            | chars: following_chars,
              start: scanner.current,
              current: scanner.current + 1
          })

        case string_scanning_result do
          {:ok, updated_scanner} ->
            scan_tokens(updated_scanner)

          {:error, msg} ->
            Lox.error(scanner.line, msg)
        end

      _ when next_token_type in [:bang_equal, :equal_equal, :less_equal, :greater_equal] ->
        scanner
        |> handle_operator(next_token_type)
        |> scan_tokens()

      _ ->
        scanner
        |> handle_single_char_token(next_token_type)
        |> scan_tokens()
    end
  end

  defp is_operator(leading_char, ["=" | _]), do: leading_char in ["!", "=", "<", ">"]
  defp is_operator(_, _), do: false

  defp operator_type(char) do
    case char do
      "!" -> :bang_equal
      "=" -> :equal_equal
      "<" -> :less_equal
      ">" -> :greater_equal
    end
  end

  defp is_string("\""), do: true
  defp is_string(_), do: false

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
          lexeme: scanner.source |> String.slice(scanner.start..(scanner.current + 1)),
          line: scanner.line
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
