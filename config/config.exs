use Mix.Config

config :logger,
backends: [{LoggerLogstashBackend, :logstash}, :console]

config :logger, :logstash,
  host: "127.0.0.1",
  port: 8080,
  level: :info,
  handler: LoggerLogstashBackend.TCP,
  type: "logstash",
  metadata: [
    key1: "value1"
  ]
