defmodule Token do
  @enforce_keys [:type, :lexeme, :line]
  defstruct [:type, :lexeme, :literal, :line]

  defimpl String.Chars, for: Token do
    def to_string(token = %Token{}) do
      IO.inspect(
        token,
        pretty: true
      )
    end
  end
end
