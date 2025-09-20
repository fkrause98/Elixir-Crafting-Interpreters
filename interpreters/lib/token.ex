defmodule Token do
  @enforce_keys [:type, :lexeme, :line]
  defstruct [:type, :lexeme, :literal, :line]

  def to_string(token = %Token{}) do
    type = Atom.to_string(token.type)
    type <> " " <> token.lexeme <> " " <> token.literal
  end
end
