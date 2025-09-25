defmodule Parser do
  def expression(tokens), do: equality(tokens)

  def equality(tokens) do
    with {:ok, {remainder, expr}} <- comparison(tokens) do
      case remainder do
        [%Token{type: type} | tokens] when type in [:bang_equal, :equal_equal] ->
          with {:ok, {[], r_expr}} <- comparison(tokens) do
            {:ok, {[], %Grammar.Binary{operator: type, l_expr: expr, r_expr: r_expr}}}
          end

        tokens ->
          {:ok, {tokens, expr}}
      end
    end
  end

  def comparison(tokens) do
    with {:ok, {remainder, l_expr}} <- term(tokens) do
      case remainder do
        [%Token{type: type} | tokens]
        when type in [:greater, :greater_equal, :less, :less_equal] ->
          with {:ok, {final_remainder, r_expr}} <- term(tokens) do
            {:ok,
             {final_remainder, %Grammar.Binary{operator: type, l_expr: l_expr, r_expr: r_expr}}}
          end

        remainder ->
          {:ok, {remainder, l_expr}}
      end
    end
  end

  def term(tokens) do
    with {:ok, {remainder, expr}} <- factor(tokens) do
      case remainder do
        [%Token{type: type} | tokens] when type in [:minus, :plus] ->
          with {:ok, {final_remainder, r_expr}} <- factor(tokens) do
            {:ok,
             {final_remainder, %Grammar.Binary{operator: type, l_expr: expr, r_expr: r_expr}}}
          end

        remainder ->
          {:ok, {remainder, expr}}
      end
    end
  end

  def factor(tokens) do
    with {:ok, {remainder, expr}} <- unary(tokens) do
      case remainder do
        [%Token{type: type} | tokens] when type in [:slash, :star] ->
          with {:ok, {remainder, r_expr}} <- unary(tokens) do
            {:ok, {remainder, %Grammar.Binary{operator: type, l_expr: expr, r_expr: r_expr}}}
          end

        tokens ->
          {:ok, {tokens, expr}}
      end
    end
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
end
