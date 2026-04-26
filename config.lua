local config = require("lapis.config")

config("development", {
  server = "nginx",
  code_cache = "off",
  cookie = {
    secure = true,
    httponly = true,
    },
  num_workers = "1",
  backend = "postgres",
  postgres = {
  host     = "127.0.0.1",
    user = "admin",
    password = "INSERT_YOUR_PASSWORD_HERE",
    database = "server_database"
    }
})
