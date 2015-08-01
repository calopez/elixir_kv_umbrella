defmodule KVServer.Command do
  @doc ~S"""
  Parse the given `line` to a command.

  ## Examples

      iex> KVServer.Command.parse "CREATE shopping\r\n"
      {:ok, {:create, "shopping"}}
  """
  def parse(line) do
    :not_implemented
  end

end
