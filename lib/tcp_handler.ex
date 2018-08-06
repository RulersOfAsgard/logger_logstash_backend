defmodule LoggerLogstashBackend.TCP do
  @moduledoc """
  TCP handler for LoggerLogstashBackend
  """
  alias LoggerLogstashBackend.TCP.Connection
  @behaviour LoggerLogstashBackend.GenericHandler

  def connect(host, port) do
    host
    |> to_charlist
    |> Connection.start_link(port, [:binary, packet: :line], 1000)
  end

  def send(conn, %{payload: payload}) do
    Connection.send(conn, payload <> "\n")
  end

  def close(conn) do
    Connection.close(conn)
  end
end
