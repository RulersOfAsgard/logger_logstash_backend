defmodule LoggerLogstashBackend.UDP do
  @moduledoc """
  UDP handler for LoggerLogstashBackend
  """
  @behaviour LoggerLogstashBackend.GenericHandler

  def connect(_host, _port) do
    :gen_udp.open(0)
  end

  def send(socket, %{host: host, port: port, payload: payload}) do
    :gen_udp.send(socket, to_charlist(host), port, to_charlist(payload))
  end

  def close(socket) do
    :gen_udp.close(socket)
    Port.close(socket)
  end
end
