defmodule Parser do
  def primary([%Token{literal: literal}]), do: {:ok, %Grammar.Primary{value: literal}}

  def primary(token), do: {:error, token}

  def unary([%Token{type: type} | tokens]) when type in [:bang, :equal] do
    case primary(tokens) do
      {:ok, primary = %Grammar.Primary{}} ->
        {:ok, %Grammar.Unary{operator: type, expr: primary}}

      {:error, _} ->
        {:ok, unary} = unary(tokens)
        {:ok, %Grammar.Unary{operator: type, expr: unary}}
    end
  end
end
