defmodule TCPHandlerTest do
  use ExUnit.Case, async: false
  require Logger
  use Timex

  @backend {LoggerLogstashBackend, :test}
  Logger.add_backend @backend

  @port 8888

  setup do
    Logger.configure_backend @backend, [
      host: "127.0.0.1",
      handler: LoggerLogstashBackend.TCP,
      port: @port,
      level: :info,
      type: "some_app",
      metadata: [
        some_metadata: "go here"
      ]
    ]
    {:ok, l_socket} = :gen_tcp.listen @port, [:binary, {:active, false}]
    {:ok, client} = :gen_tcp.accept(l_socket)
    on_exit fn ->
      :ok = :gen_tcp.close(l_socket)
    end
    :ok
    %{client: client}
  end

  test "if we can log", %{client: client} do
    Logger.info("test message", [key1: :value1])
    {:ok, data} = :gen_tcp.recv(client, 0)

    assert(String.contains?(data, "value1"))
  end
end
