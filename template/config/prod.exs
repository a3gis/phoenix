use Mix.Config

config :phoenix, <%= application_module %>.Router,
  port: System.get_env("PORT"),
  ssl: false,
  code_reload: false,
  cookies: true,
  session_key: "_<%= application_name %>_key",
  session_secret: "<%= session_secret %>"

config :phoenix, :logger,
  level: :error

