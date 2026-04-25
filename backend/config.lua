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
    user = "admin",
    password = "uzb)hrz64gcZk^B[",
    database = "server_database"
    }
})
