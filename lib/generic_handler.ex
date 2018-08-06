defmodule LoggerLogstashBackend.GenericHandler do
  @moduledoc """
  Behaviour for LoggerLogstashBackend handlers
  """
  defstruct [:host, :port, :payload]

  @callback connect(String.t, non_neg_integer) :: {:ok, port() | pid()} | {:error, atom}
  @callback send(port() | pid(), %LoggerLogstashBackend.GenericHandler{}) :: :ok | {:error, atom}
  @callback close(port() | pid()) :: :ok
end
