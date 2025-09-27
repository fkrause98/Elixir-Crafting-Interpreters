defmodule Parser do
  def parse_token_stream(tokens) do
    case expression(tokens) do
      {:ok, result} ->
        {:ok, result}

      {:error, err} ->
        IO.puts("Parse error: #{err}")
        {:error, err}
    end
  end

  def expression(tokens), do: equality(tokens)

  def equality(tokens) do
    do_parse(tokens, &comparison/1, [:bang_equal, :equal_equal])
  end

  def comparison(tokens) do
    do_parse(tokens, &term/1, [:greater, :greater_equal, :less, :less_equal])
  end

  def term(tokens) do
    do_parse(tokens, &factor/1, [:minus, :plus])
  end

  def factor(tokens) do
    do_parse(tokens, &unary/1, [:slash, :star])
  end

  def unary([%Token{type: operator} | tokens]) when operator in [:bang, :minus] do
    case unary(tokens) do
      {:ok, {remainder, right}} ->
        {:ok, {remainder, %Grammar.Unary{operator: operator, expr: right}}}

      {:error, err} ->
        {:error, err}
    end
  end

  def unary(tokens), do: primary(tokens)

  def primary([%Token{type: :left_paren, line: line} | tokens]) do
    case expression(tokens) do
      {:ok, {[%Token{type: :right_paren} | tokens], expr}} ->
        {:ok, {tokens, %Grammar.Grouping{expr: expr}}}

      {:ok, {[next_token | _], _expr}} ->
        {:error,
         "Missing closing parenthesis at line #{line}. Found '#{next_token.lexeme}' at line #{next_token.line}"}

      {:ok, {[], _expr}} ->
        {:error, "Missing closing parenthesis at line #{line}. Reached end of input"}

      err = {:error, _} ->
        err
    end
  end

  def primary([%Token{literal: literal} | tokens]) when literal != nil do
    {:ok, {tokens, %Grammar.Primary{value: literal}}}
  end

  def primary([]), do: {:error, "Unexpected end of input"}

  def primary([%Token{type: type, lexeme: lexeme, line: line} | _]) do
    {:error, "Unexpected token '#{lexeme}' (#{type}) at line #{line}"}
  end

  defp do_parse(tokens, next, types) do
    case next.(tokens) do
      {:ok, {remainder, expr}} ->
        parse_binary_chain(remainder, expr, next, types)

      {:error, err} ->
        {:error, err}
    end
  end

  defp parse_binary_chain([], expr, _next, _types), do: {:ok, {[], expr}}
  defp parse_binary_chain([token], expr, _next, _types), do: {:ok, {[token], expr}}

  defp parse_binary_chain([%Token{type: type} = token | remaining_tokens], left_expr, next, types) do
    if type in types do
      parse_binary_operator(remaining_tokens, left_expr, type, next, types)
    else
      {:ok, {[token | remaining_tokens], left_expr}}
    end
  end

  defp parse_binary_operator(tokens, left_expr, operator, next, types) do
    case next.(tokens) do
      {:ok, {remainder, right_expr}} ->
        binary_expr = %Grammar.Binary{operator: operator, l_expr: left_expr, r_expr: right_expr}
        parse_binary_chain(remainder, binary_expr, next, types)

      {:error, err} ->
        {:error, err}
    end
  end

  defp synchronize(tokens) when is_list(tokens) do
    tokens = Enum.drop_while(tokens, &synchronize_stop?/1)
    {:ok, tokens}
  end

  defp synchronize_stop?(%Token{type: token_type}) do
    token_type not in [:class, :fun, :for, :if, :while, :print, :return]
  end
end
