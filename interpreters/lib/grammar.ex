defmodule Grammar do
  @type expression :: Literal.t() | Unary.t() | BinaryOp.t() | Grouping.t()
  @type literal :: Float.t() | String.t() | true | false | nil
  @type operator ::
          :equal_equal
          | :bang_equal
          | :less
          | :less_equal
          | :greater
          | :greater_equal
          | :plus
          | :minus
          | :star
          | :slash
          | :bang
          | :equal

  defmodule Literal do
    @enforce_keys [:value]
    defstruct [:value]
    @type t :: %__MODULE__{value: Grammar.literal()}

    def from_token(%Token{literal: value}) do
      {:ok,
       %Grammar.Literal{
         value: value
       }}
    end

    def from_token(token = %Token{literal: nil}) do
      {:error, "Cannot build a Grammar Literal value from token of type: #{token.type}"}
    end
  end

  defmodule Grouping do
    @enforce_keys [:expr]
    defstruct [:expr]
    @type t :: %__MODULE__{expr: Grammar.expression()}
  end

  defmodule Unary do
    @enforce_keys [:modifier, :expr]
    defstruct [:modifier, :expr]
    @type t :: %__MODULE__{modifier: Grammar.operator(), expr: Grammar.expression()}
  end

  defmodule BinaryOp do
    @enforce_keys [:l_expr, :op, :r_expr]
    defstruct [:l_expr, :op, :r_expr]

    @type t :: %__MODULE__{
            l_expr: Grammar.expression(),
            op: Grammar.operator(),
            r_expr: Grammar.expression()
          }
  end
end

defmodule Grammar.Traverse do
  alias Grammar.{Literal, Grouping, Unary, BinaryOp}

  defprotocol ASTRepr do
    def repr(grammar)
  end

  defimpl ASTRepr, for: [Literal, Grouping, Unary, BinaryOp, Atom] do
    def repr(%Literal{value: value}), do: value |> to_string()

    def repr(%Grouping{expr: expr}), do: "(group " <> repr(expr) <> ")"

    def repr(%BinaryOp{op: operator, l_expr: l_expr, r_expr: r_expr}) do
      stringified_operator =
        case operator do
          :plus -> "+"
          :minus -> "-"
          :star -> "*"
          :slash -> "/"
          :bang_equal -> "!="
          :equal_equal -> "=="
          :less -> "<"
          :less_equal -> "<="
          :greater -> ">"
          :greater_equal -> ">="
        end

      "(" <> stringified_operator <> " " <> repr(l_expr) <> " " <> repr(r_expr) <> " )"
    end

    def repr(%Unary{modifier: mod, expr: expr}),
      do: "(" <> to_string(mod) <> " " <> repr(expr) <> " )"
  end
end
