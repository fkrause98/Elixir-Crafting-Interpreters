defmodule Grammar do
  defmodule Primary do
    @type t :: %Primary{value: Float.t() | String.t() | nil | false | true}
    defstruct [:value]
  end

  defmodule Unary do
    @type t :: %Unary{operator: :bang | :minus, expr: Unary.t() | Primary.t()}
    defstruct [:operator, :expr]
  end
end
