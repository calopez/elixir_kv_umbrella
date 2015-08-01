defmodule KVServer do
  use Application

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor, [[name: KVServer.TaskSupervisor]]),
      worker(Task, [KVServer, :accept, [4040]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KVServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of list)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr`: true - allows us to reuse the address if the listiner crashes

    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false,
                                            reuseaddr: true])

    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)

    :ok = :gen_tcp.controlling_process(client, pid)
    # This ^ makes the child process the "controlling process" of the
    # client socket. If we didn't do this, the acceptor would bring down
    # all the clients if it crashed because sockets are tied to the
    # process that accepted them by default.

    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket) # is equivalent to: write_line(read_line(socket), socket)

    serve(socket)
  end

  defp read_line(socket) do
      {:ok, data} = :gen_tcp.recv(socket, 0)
      "this is what you wrote: #{data}"
  end

  defp write_line(line, socket) do
       :gen_tcp.send(socket, line)
  end

end
