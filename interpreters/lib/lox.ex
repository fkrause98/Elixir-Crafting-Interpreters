defmodule Lox do
  def main(args) do
    case args do
      [] ->
        loop()

      [script_file] ->
        run_file(script_file)

      _ ->
        IO.puts("Usage: jlox [script]")
    end
  end

  defp run_file(path) do
    {:ok, file_contents} = File.read(path)
    run(file_contents)
  end

  defp run(source) do
    with {:ok, tokens} <- Scanner.tokenize_source(source),
         {:ok, {_, parsed}} <- Parser.parse_token_stream(tokens) do
      IO.inspect(parsed)
    end
  end

  def error(line, message) do
    report(line, "", message)
  end

  defp report(line, where, message) do
    msg = "[line #{line}] Error#{where}:  #{message}"
    IO.puts(:stderr, msg)
    {:error, msg}
  end

  defp loop() do
    IO.write("lox> ")
    line = IO.gets("") |> String.trim()

    case line do
      "exit" ->
        IO.puts("Goodbye!")

      "" ->
        loop()

      input ->
        run(input)
        loop()
    end
  end
end
