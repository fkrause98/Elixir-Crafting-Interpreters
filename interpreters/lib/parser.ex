defmodule Parser do
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

  def unary([%Token{type: type} | tokens]) when type in [:bang, :minus] do
    case primary(tokens) do
      {:ok, {remainder, primary}} ->
        {:ok, {remainder, %Grammar.Unary{operator: type, expr: primary}}}

      {:error, _} ->
        with {:ok, {remainder, unary_expr}} <- unary(tokens) do
          {:ok, {remainder, %Grammar.Unary{operator: type, expr: unary_expr}}}
        end
    end
  end

  def unary(tokens), do: primary(tokens)

  def primary([%Token{literal: literal} | tokens]) do
    {:ok, {tokens, %Grammar.Primary{value: literal}}}
  end

  def primary(tokens), do: {:error, {tokens, nil}}

  defp do_parse(tokens, next, types) do
    with {:ok, {remainder, expr}} <- next.(tokens) do
      case remainder do
        [%Token{type: type} | tokens] ->
          case next.(tokens) do
            {:ok, {remainder, r_expr}} ->
              {:ok, {[], %Grammar.Binary{operator: type, l_expr: expr, r_expr: r_expr}}}

            {:error, err} ->
              :error
          end

        tokens ->
          {:ok, {tokens, expr}}
      end
    end
  end
end
