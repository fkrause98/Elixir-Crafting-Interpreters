defmodule Parser do
  def parse_token_stream(tokens) do
    Parser.expression(tokens)
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

  def primary([%Token{type: :left_paren} | tokens]) do
    case expression(tokens) do
      {:ok, {[%Token{type: :right_paren} | tokens], expr}} ->
        {:ok, {tokens, %Grammar.Grouping{expr: expr}}}

      err = {:error, _} ->
        err
    end
  end

  def primary([%Token{literal: literal} | tokens]) when literal != nil do
    {:ok, {tokens, %Grammar.Primary{value: literal}}}
  end

  def primary(tokens), do: {:error, {tokens, nil}}

  defp do_parse(tokens, next, types) do
    case next.(tokens) do
      {:ok, {remainder, expr}} ->
        case remainder do
          [] ->
            {:ok, {[], expr}}

          [token] ->
            {:ok, {[token], expr}}

          [%Token{type: type} | tokens] ->
            case next.(tokens) do
              {:ok, {remainder, r_expr}} ->
                {:ok, {remainder, %Grammar.Binary{operator: type, l_expr: expr, r_expr: r_expr}}}

              {:error, err} ->
                IO.puts("error parsing binary exp: #{err}")

                synchronize(tokens)
            end
        end

      {:error, err} ->
        IO.puts("error parsing: #{err}")
        synchronize(tokens)
    end
  end

  defp synchronize(tokens) when is_list(tokens) do
    tokens = Enum.drop_while(tokens, &synchronize_stop?/1)
  end

  defp synchronize_stop?(%Token{type: token_type}) do
    token_type in [:class, :fun, :for, :if, :while, :print, :return]
  end
end
