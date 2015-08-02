# Since we have used unit tests so far, this time we will take the
# other road and write an integration test. The integration test will
# have a TCP client that sends commands to our server and we will assert
# that we are getting the desired responses.
#
# The downside of integration tests is that they can be much slower than
# unit tests, and as such they must be used more sparingly


defmodule KVServerTest do
  use ExUnit.Case
  #  Since our test relies on global data, we have not given async: true
  #  to use ExUnit.Case.


  setup do
    # In order to guarantee our test is always in a clean state,
    # we stop and start the :kv application before each test
    :application.stop(:kv)
    :ok = :application.start(:kv)
    Logger.add_backend(:console, flush: true)
    :ok
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    {:ok, socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert send_and_recv(socket, "UNKNOWN shopping\r\n") ==
           "UNKNOWN COMMAND\r\n"

    assert send_and_recv(socket, "GET shopping eggs\r\n") ==
           "NOT FOUND\r\n"

    assert send_and_recv(socket, "CREATE shopping\r\n") ==
           "OK\r\n"

    assert send_and_recv(socket, "PUT shopping eggs 3\r\n") ==
           "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "3\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"

    assert send_and_recv(socket, "DELETE shopping eggs\r\n") ==
           "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    data
  end
end
