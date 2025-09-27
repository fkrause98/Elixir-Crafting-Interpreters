defmodule Grammar do
  defmodule Primary do
    @type t :: %Primary{value: Float.t() | String.t() | :null | false | true}
    defstruct [:value]

    defimpl String.Chars, for: Grammar.Primary do
      def to_string(%{value: value}), do: Kernel.to_string(value)
    end
  end

  defmodule Unary do
    @type t :: %Unary{operator: :bang | :minus, expr: Unary.t() | Primary.t()}
    defstruct [:operator, :expr]

    defimpl String.Chars, for: Grammar.Unary do
      def to_string(unary) do
        unary.operator <> String.Chars.to_string(unary.expr)
      end
    end
  end

  defmodule Binary do
    defstruct [:operator, :l_expr, :r_expr]

    defimpl String.Chars, for: Grammar.Binary do
      def to_string(binary) do
        Kernel.to_string(binary.operator) <>
          " " <>
          Kernel.to_string(binary.l_expr) <>
          " " <>
          Kernel.to_string(binary.r_expr)
      end
    end
  end

  defmodule Grouping do
    defstruct [:expr]

    defimpl String.Chars, for: Grammar.Grouping do
      def to_string(%{expr: expr}) do
        "(  " <> Kernel.to_string(expr) <> " )"
      end
    end
  end
end
