defmodule InterpretersTest.Scanner do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @simple_values [
    {"(", :left_paren},
    {")", :right_paren},
    {"{ ", :left_brace},
    {"}", :right_brace},
    {",", :comma},
    {".", :dot},
    {"-", :minus},
    {"+", :plus},
    {";", :semicolon},
    {"*", :star}
  ]

  # test "Scanner reports error with unknown char" do
  #   assert capture_io(:stderr, fn ->
  #            Scanner.from_source("#") |> Scanner.scan_tokens()
  #          end) =~ "Unexpected token"
  # end

  # test "Scanner handles multiline" do
  #   new_lines = 1..10 |> Enum.map(fn _ -> "\n" end) |> Enum.join(" ")
  #   source = "{ #{new_lines} }"
  #   assert {:ok, [%{line: 0}, %{line: 10}]} = Scanner.from_source(source) |> Scanner.scan_tokens()
  # end

  # test "Scanner reports error at correct line" do
  #   new_lines = 1..10 |> Enum.map(fn _ -> "\n" end) |> Enum.join(" ")
  #   source = "{ #{new_lines} # }"

  #   assert capture_io(:stderr, fn ->
  #            Scanner.from_source(source) |> Scanner.scan_tokens()
  #          end) =~ "line 10"
  # end

  # test "Scanner handles two-char token" do
  #   sources_and_expected_type = [
  #     {"!=", :bang_equal},
  #     {"<=", :less_equal},
  #     {">=", :greater_equal},
  #     {"==", :equal_equal}
  #   ]

  #   for {source, expected_type} <- sources_and_expected_type do
  #     {:ok, [token]} = source |> Scanner.from_source() |> Scanner.scan_tokens()

  #     assert token ==
  #              %Token{type: expected_type, lexeme: source, literal: nil, line: 0}
  #   end
  # end

  # test "Scanner handles empty string" do
  #   {:ok, [token]} = " \"\" " |> Scanner.from_source() |> Scanner.scan_tokens()

  #   assert token.type == :string
  # end

  # test "Scanner handles simple string" do
  #   {:ok, [token]} =
  #     " \"You broke my heart, fredo \" " |> Scanner.from_source() |> Scanner.scan_tokens()

  #   assert token.type == :string
  #   assert token.literal =~ "You broke my heart, fredo"
  # end

  # test "Scanner handles multiline string" do
  #   {:ok, [token]} =
  #     "\"I know it was you. \n You broke my heart, fredo. \n You broke my heart \""
  #     |> Scanner.from_source()
  #     |> Scanner.scan_tokens()

  #   assert token.type == :string
  #   assert token.literal =~ "I know it was you"
  #   assert token.literal =~ "You broke my heart, fredo"
  #   assert token.literal =~ "You broke my heart"
  # end

  # test "Scanner reports unfinished string" do
  #   assert capture_io(:stderr, fn ->
  #            "\" I'm going to make him an offer he can't refuse"
  #            |> Scanner.from_source()
  #            |> Scanner.scan_tokens()
  #          end) =~ "Unfinished string"
  # end
end
