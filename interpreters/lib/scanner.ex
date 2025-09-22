defmodule Scanner.Parser do
  import NimbleParsec
  single_integer = integer(min: 1) |> lookahead_not(string("."))
  integer_point_and_decimal = integer(min: 1) |> string(".") |> integer(min: 1)

  def float_parse([input]) when is_integer(input), do: input / 1.0

  def float_parse([integer_part, ".", decimal_part]) do
    {parsed, ""} = Float.parse("#{integer_part}.#{decimal_part}")
    parsed
  end

  decimal_parser =
    choice([
      single_integer,
      integer_point_and_decimal
    ])
    |> reduce({:float_parse, []})

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
      string("*"),
      string("/")
    ])

  defparsec(:token, single_char_parser |> post_traverse({:tokenize, []}))

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

  operator = choice([two_token_operator, one_token_operator])

  defparsec(:operator, operator)

  escaped_char = ascii_char([?\\]) |> utf8_char([])
  string_char = choice([escaped_char, utf8_char([{:not, ?"}])])

  defp build_string(rest, consumed_chars, context, {line, _col}, _offset) do
    unterminated? =
      Enum.find(consumed_chars, fn elem -> match?({:unterminated_string, _}, elem) end)

    if unterminated? do
      {:error, "Unterminated string at line #{line}"}
    else
      {rest, [consumed_chars |> Enum.reverse() |> List.to_string()], context}
    end
  end

  literal_string_parser =
    ascii_char([?"])
    |> repeat(string_char)
    |> choice([ascii_char([?"]), empty() |> tag(:unterminated_string)])
    |> post_traverse({:build_string, []})

  defparsec(
    :literal_string,
    literal_string_parser
  )

  whitespace =
    choice([
      string(" "),
      string("\t"),
      string("\r"),
      string("\n") |> replace(:newline)
    ])
    |> ignore()

  defp not_newline(<<?\n, _::binary>>, context, _, _), do: {:halt, context}
  defp not_newline(_, context, _, _), do: {:cont, context}

  comment =
    string("//")
    |> repeat_while(utf8_char([]), :not_newline)
    |> optional(string("\n"))
    |> ignore()

  boolean =
    choice([
      string("true"),
      string("false"),
      string("nil")
    ])

  defparsec(
    :lox_syntax,
    choice([
      whitespace |> ignore,
      comment |> ignore,
      boolean |> tag(:bool),
      literal_string_parser |> unwrap_and_tag(:string),
      decimal_parser |> unwrap_and_tag(:number),
      single_char_parser,
      one_token_operator |> tag(:single_token_operator),
      two_token_operator |> tag(:double_token_operator),
      utf8_char([]) |> tag(:unknown_char)
    ])
    |> repeat
    |> post_traverse({:tokenize, []})
  )

  defp tokenize([lexeme], line, :double_token_operator) do
    case Scanner.Helpers.double_operator_type(lexeme) do
      :unknown ->
        {:error, "Unknown double operator in line #{line}: #{lexeme}"}

      type ->
        {:ok, %Token{type: type, lexeme: lexeme, literal: nil, line: line}}
    end
  end

  defp tokenize([lexeme], line, :single_token_operator) do
    case Scanner.Helpers.operator_type(lexeme) do
      :unknown ->
        {:error, "Unknown single operator in line #{line}: #{lexeme}"}

      type ->
        {:ok, %Token{type: type, lexeme: lexeme, literal: nil, line: line}}
    end
  end

  defp tokenize(num, line, :number) when is_float(num) do
    {:ok, %Token{type: :number, lexeme: nil, literal: num, line: line}}
  end

  defp tokenize(string, line, type = :string) do
    case String.split(string, "\"") do
      ["", string_content, ""] ->
        {:ok, %Token{type: type, lexeme: nil, literal: string_content, line: line}}

      _ ->
        {:error, "Malformed string literal in line #{line}: #{string}"}
    end
  end

  defp tokenize([bool], line, :bool),
    do:
      {:ok,
       %Token{type: :boolean, literal: String.to_existing_atom(bool), line: line, lexeme: nil}}

  defp tokenize(char, line, :unknown_char) do
    {:error, "Unknown character in line #{line}: #{char}"}
  end

  defp tokenize(char, line) do
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
        char == "/" -> :slash
      end

    case token_type do
      :unknown ->
        {:error, "Unknown character in line #{line}: #{char}"}

      _ ->
        {:ok, %Token{type: token_type, lexeme: char, literal: nil, line: line}}
    end
  end

  defp tokenize(rest, args, context, {line, _col}, _offset) do
    {tokens, errors, _current_line} =
      Enum.reduce(
        args,
        {[], [], line},
        fn
          :newline, {acc, errors, current_line} ->
            {acc, errors, current_line + 1}

          char, {acc, errors, current_line} when char in ["\r", "\t", " "] ->
            {acc, errors, current_line}

          {token_type, raw_token}, {acc, errors, current_line} ->
            case tokenize(raw_token, current_line, token_type) do
              {:ok, token} -> {[token | acc], errors, current_line}
              {:error, msg} -> {acc, [msg | errors], current_line}
            end

          raw_elem, {acc, errors, current_line} ->
            case tokenize(raw_elem, current_line) do
              {:ok, token} -> {[token | acc], errors, current_line}
              {:error, msg} -> {acc, [msg | errors], current_line}
            end
        end
      )

    updated_context = Map.put(context, :errors, Enum.reverse(errors))
    {rest, Enum.reverse(tokens), updated_context}
  end
end

defmodule Scanner.Helpers do
  def is_operator(leading_char, ["=" | _]), do: leading_char in ["!", "=", "<", ">"]
  def is_operator(_, _), do: false

  def operator_type("!"), do: :bang
  def operator_type("="), do: :equal
  def operator_type("<"), do: :less
  def operator_type(">"), do: :greater

  def double_operator_type("!="), do: :bang_equal
  def double_operator_type("=="), do: :equal_equal
  def double_operator_type("<="), do: :less_equal
  def double_operator_type(">="), do: :greater_equal

  def is_string("\""), do: true
  def is_string(_), do: false

  defguard is_digit(char) when char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
end

defmodule Scanner do
  @enforce_keys [:source, :chars, :tokens, :line, :start, :current]
  defstruct [:source, :chars, tokens: [], current: 0, line: 0, start: 0]

  def tokenize_source(source) do
    case Scanner.Parser.lox_syntax(source) do
      {:ok, [], "", %{errors: err_msgs}, _, _} ->
        {:error, err_msgs |> Enum.reverse()}

      {:ok, tokens, _, %{}, _, _} ->
        {:ok, tokens}

      {:error, err_msg, _, %{}, _, _} ->
        {:error, err_msg}

      {:error, err_msg} ->
        {:error, err_msg}
    end
  end
end
