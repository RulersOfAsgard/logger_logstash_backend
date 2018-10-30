################################################################################
# Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
defmodule LoggerLogstashBackendTest do
  use ExUnit.Case, async: false
  require Logger
  use Timex

  @backend {LoggerLogstashBackend, :test}
  Logger.add_backend @backend

  setup do
    Logger.configure_backend @backend, [
      host: "127.0.0.1",
      handler: LoggerLogstashBackend.UDP,
      port: 10001,
      level: :info,
      type: "some_app",
      metadata: [
        some_metadata: "go here"
      ]
    ]
    {:ok, socket} = :gen_udp.open 10001, [:binary, {:active, true}]
    on_exit fn ->
      :ok = :gen_udp.close socket
    end
    :ok
  end

  test "can log" do
    Logger.info "hello world", [key1: "field1"]
    {ts, expected, data} = parse_data(43, %{"key1" => "field1"})
    now = Timex.to_unix Timex.local
    assert data["type"] === "some_app"
    assert data["message"] === "hello world"
    assert contains?(data, expected)
    assert (now - ts) < 1000
  end

  test "can log pids" do
    Logger.info "pid", [pid_key: self()]
    {ts, expected, data} = parse_data(53, %{"pid_key" => inspect(self()),
                                            "function" => "test can log pids/1"})
    now = Timex.to_unix Timex.local
    assert data["type"] === "some_app"
    assert data["message"] === "pid"
    assert contains?(data, expected)
    assert (now - ts) < 1000
  end

  test "cant log when minor levels" do
    Logger.debug "hello world", [key1: "field1"]
    :nothing_received = get_log()
  end

  test "test CEST to CET datetime saving swicht period" do
    {:ok, data} = log_custom_date({{2018, 10, 28}, {1, 59, 0, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2018, 10, 28}, {2, 0, 0, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2018, 10, 28}, {2, 12, 32, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2018, 10, 28}, {3, 0, 0, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2018, 10, 28}, {3, 1, 0, 0}})
    assert data["message"] === "log message"
  end

  test "test CET to CEST datetime saving switch period" do
    {:ok, data} = log_custom_date({{2019, 3, 31}, {1, 59, 0, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2019, 3, 31}, {2, 0, 0, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2019, 3, 31}, {2, 12, 32, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2019, 3, 31}, {3, 0, 0, 0}})
    assert data["message"] === "log message"
    {:ok, data} = log_custom_date({{2019, 3, 31}, {3, 1, 0, 0}})
    assert data["message"] === "log message"
  end

  def parse_data(line_nr, extra_fields) do
    json = get_log()
    {:ok, data} = JSX.decode json
    {:ok, ts} = Timex.parse data["@timestamp"], "{ISO:Extended}"
    ts = Timex.to_unix ts
    expected = %{
      "function" => "test can log/1",
      "level" => "info",
      "module" => "Elixir.LoggerLogstashBackendTest",
      "pid" => (inspect self()),
      "some_metadata" => "go here",
      "line" => line_nr
    }
    |> Map.merge(extra_fields)

    {ts, expected, data}
  end

  defp get_log do
    receive do
      {:udp, _, _, _, json} -> json
    after 500 -> :nothing_received
    end
  end

  defp contains?(map1, map2) do
    Enum.all?(Map.to_list(map2), fn {key, value} ->
      Map.fetch!(map1, key) == value
    end)
  end

  defp log_custom_date(date_tuple) do
    [{_backend, _type, state} | _tail] = :sys.get_state(Logger)
    LoggerLogstashBackend.handle_event(
      {:error, node(), {Logger, "log message", date_tuple, []}}, state)
    json = get_log()
    JSX.decode json
  end
end
