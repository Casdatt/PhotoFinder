local random = require("resty.random")
local str    = require("resty.string")
local bcrypt = require("bcrypt")

local lapis = require("lapis")
local db    = require("lapis.db")

---------

-- We declare the tables and insert some default data.
ngx.timer.at(0, function(premature)
    if premature then return end
    db.query([[
      CREATE TABLE IF NOT EXISTS users (
        id            SERIAL    PRIMARY KEY,
        username      TEXT      NOT NULL UNIQUE,
        password_hash TEXT      NOT NULL,
        token         TEXT      UNIQUE,
        token_expires TIMESTAMP,
        created_at    TIMESTAMP DEFAULT NOW()
      )
    ]])
    db.query([[
      CREATE TABLE IF NOT EXISTS globos (
        id          SERIAL PRIMARY KEY,
        user_id     INTEGER REFERENCES users(id),
        image_path  TEXT         NOT NULL,
        lat         NUMERIC(9,6) NOT NULL,
        lon         NUMERIC(9,6) NOT NULL,
        rating      NUMERIC(2,1) NOT NULL DEFAULT 0
                                CHECK (rating >= 0 AND rating <= 5
                                AND rating * 2 = FLOOR(rating * 2)),
        created_at  TIMESTAMP   DEFAULT NOW(),
        lifetime    INTERVAL    NOT NULL DEFAULT '2 hours',
        expires_at  TIMESTAMP   GENERATED ALWAYS AS (created_at + lifetime) STORED
      )
    ]])

    -- Default globos and their user
    db.query([[
        INSERT INTO users (username, password_hash)
        VALUES ('_system', 'no-login')
        ON CONFLICT (username) DO NOTHING
    ]])
    local system_user = db.select("id FROM users WHERE username = '_system'")[1]
    if not system_user then return end
    local uid = system_user.id

    local seed_globos = {
        { path = "/static/globos/",    lat =  0, lon = 0  }
    }

    for _, g in ipairs(seed_globos) do
        db.query([[
            INSERT INTO globos (user_id, image_path, lat, lon, lifetime)
            VALUES (?, ?, ?, ?, INTERVAL 'infinity')
            ON CONFLICT DO NOTHING
        ]], uid, g.path, g.lat, g.lon)
    end
end)

--

local function hash_password(password)
    return bcrypt.digest(password, 12)
end

local function verify_password(password, hash)
    return bcrypt.verify(password, hash)
end

local function generate_token()
    return str.to_hex(random.bytes(32, true))
end

local function get_current_user(self)
  local token = self.session.token
  if not token then return nil end
  return db.select("* FROM users WHERE token = ? AND token_expires > NOW()", token)[1]
end

---------

local tick_count = 0

local function on_tick(premature)
    if premature then return end
    tick_count = tick_count + 1

    db.query("DELETE FROM globos WHERE expires_at < NOW()")

    if tick_count % 5 == 0 then
        -- Add the erase uploaded images logic here.
    end
    ngx.timer.at(360, on_tick)
end
ngx.timer.at(0, on_tick)

---------



local app = lapis.Application()
      app:enable("etlua")
      app.layout = require "views.layout"

app:get("/", function(self)
  return { render = "index" }
end)


app:get("/login", function(self)
  return { render = "login" }
end)

--[[app:post("/login", function(self)
    local username = self.params.username
    local password = self.params.password

    -- Basic input validation
    if not username or not password or username == "" or password == "" then
        return {
            render = "login",
            status = 400,
            error  = "Username and password are required."
        }
    end

    -- Look up user
    local user = db.select("* FROM users WHERE username = ?", username)[1]

    if not user or not verify_password(password, user.password_hash) then
        return {
            render = "login",
            status = 401,
            error  = "Invalid username or password."
        }
    end

    -- Generate token and set expiry (7 days)
    local token   = generate_token()
    local expires = db.raw("NOW() + INTERVAL '7 days'")

    db.query(
        "UPDATE users SET token = ?, token_expires = ? WHERE id = ?",
        token, expires, user.id
    )

    -- Store token in session cookie
    self.session.token = token

    return { redirect_to = "/" }
end)]]


app:get("/register", function(self)
  return { render = "register" }
end)

app:get("/leaderboard", function(self)
  return { render = "leaderboard" }
end)

app:get("/about", function(self)
  return { render = "about" }
end)
    
app:get("/search", function(self)
  return { render = "search"}
end)

app:get("/play", function(self)
  return { render = "play" }
end)

return app
