local random = require("resty.random")
local str    = require("resty.string")
local bcrypt = require("bcrypt")

local magick = require("magick")

local lapis = require("lapis")
local db    = require("lapis.db")

---------

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
        lat         NUMERIC(12,8) NOT NULL,
        lon         NUMERIC(12,8) NOT NULL,
        rating      NUMERIC(2,1) NOT NULL DEFAULT 3
                                CHECK (rating >= 0 AND rating <= 5
                                AND rating * 2 = FLOOR(rating * 2)),
        created_at  TIMESTAMP   DEFAULT NOW(),
        lifetime    INTERVAL    NOT NULL DEFAULT '2 hours',
        expires_at  TIMESTAMP   GENERATED ALWAYS AS (created_at + lifetime) STORED
      )
    ]])

    db.query([[
      CREATE TABLE IF NOT EXISTS ratings (
        id         SERIAL    PRIMARY KEY,
        globo_id   INTEGER   REFERENCES globos(id) ON DELETE CASCADE,
        user_id    INTEGER   REFERENCES users(id),
        score      NUMERIC(2,1) NOT NULL
                             CHECK (score >= 0 AND score <= 5
                             AND score * 2 = FLOOR(score * 2)),
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE (globo_id, user_id)
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
        { path = "/static/globos/defaults/location1.webp",    lat =  41.3887952, lon = 2.1129702  },
        { path = "/static/globos/defaults/location1.webp",    lat =  41.3880330, lon = 2.1117172  },
        { path = "/static/globos/defaults/location1.webp",    lat =  41.3886677, lon = 2.1109759  },
        { path = "/static/globos/defaults/location1.webp",    lat =  41.3881492, lon = 2.1139274  }
    }

    for _, g in ipairs(seed_globos) do
        db.query([[
            INSERT INTO globos (user_id, image_path, lat, lon, lifetime)
            VALUES (?, ?, ?, ?, INTERVAL '9999999 hours')
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
        local active = db.select("image_path FROM globos")
        local active_set = {}
        for _, row in ipairs(active) do
            active_set[row.image_path] = true
        end

        local handle = io.popen("find static/globos -maxdepth 1 -type f")
        if handle then
            for filepath in handle:lines() do
                local normalized = "/" .. filepath
                if not active_set[normalized] then
                    os.remove(filepath)
                end
            end
            handle:close()
        end
    end
    ngx.timer.at(360, on_tick)
end
ngx.timer.at(0, on_tick)

---------

local function require_login(fn)
    return function(self)
        local user = get_current_user(self)
        if not user then
            return { redirect_to = "/login" }
        end
        self.current_user = user
        return fn(self)
    end
end

local app = lapis.Application()
      app:enable("etlua")
      app.layout = require "views.layout"

app:before_filter(function(self)
    self.current_user = get_current_user(self)
end)

app:get("/", function(self)
  return { render = "index" }
end)


app:get("/login", function(self)
  return { render = "login" }
end)


app:post("/login", function(self)
    local username = self.params.username
    local password = self.params.password

    if not username or not password or username == "" or password == "" then
        self.err  = "Username and password are required."
        return {render = "login", status = 400}
    end

    local user = db.select("* FROM users WHERE username = ?", username)[1]

    if not user or not verify_password(password, user.password_hash) then
        self.err = "Invalid username or password."
        return { render = "login", status = 401 }
    end

    local token   = generate_token()
    local expires = db.raw("NOW() + INTERVAL '7 days'")

    db.query(
        "UPDATE users SET token = ?, token_expires = ? WHERE id = ?",
        token, expires, user.id
    )

    -- Store token in session cookie
    self.session.token = token

    return { redirect_to = "/" }
end)


app:get("/register", function(self)
  return { render = "register" }
end)

app:post("/register", function(self)
local username = self.params.username
    local password = self.params.password
    local confirm  = self.params.confirm_password

    -- Basic validation
    if not username or username == "" then
        self.err = "Username is required."
        return { render = "register", status = 400, form_username = username }
    end
    if not password or password == "" then
        self.err = "Password is required."
        return { render = "register", status = 400 }
    end
    if password ~= confirm then
        self.err = "Passwords do not match."
        return { render = "register", status = 400 }
    end
    if #username < 3 or #username > 32 then
        self.err = "Username must be between 3 and 32 characters."
        return { render = "register", status = 400 }
    end
    if #password < 8 then
        self. err = "Password must be at least 8 characters."
        return { render = "register", status = 400 }
    end

    -- Check for existing user
    local existing = db.select("id FROM users WHERE username = ?", username)[1]
    if existing then
        self.err = "Username already taken."
        return { render = "register", status = 409 }
    end

    -- Hash and insert
    local hash  = hash_password(password)
    local token = generate_token()
    local expires = db.raw("NOW() + INTERVAL '7 days'")

    db.query(
        "INSERT INTO users (username, password_hash, token, token_expires) VALUES (?, ?, ?, ?)",
        username, hash, token, expires
    )

    -- Log them in immediately
    self.session.token = token

    return { redirect_to = "/" }
end)

app:get("/logout", function(self)
    self.session.token = nil
    return { redirect_to = "/" }
end)


app:get("/api/globo/random", require_login(function(self)
    local globo = db.select("* FROM globos WHERE expires_at > NOW() AND user_id != ? ORDER BY RANDOM() LIMIT 1", self.current_user.id)[1]

    if not globo then
        return { json = { error = "No globos available" }, status = 404 }
    end

    return { json = {
        id         = globo.id,
        image_path = globo.image_path,
        lat        = globo.lat,
        lon        = globo.lon,
        rating     = globo.rating,
        expires_at = globo.expires_at,
        created_at = globo.created_at
    }}
end))

app:post("/api/globo/upload", require_login(function(self)
    local file = self.params.image
    local lat  = tonumber(self.params.lat)
    local lon  = tonumber(self.params.lon)
        
    if not file or not file.content or file.content == "" then
        return { json = { error = "Image is required." }, status = 400 }
    end
    if not lat or not lon then
        return { json = { error = "lat and lon are required numeric values." }, status = 400 }
    end
    if lat < -90 or lat > 90 or lon < -180 or lon > 180 then
        return { json = { error = "lat/lon out of range." }, status = 400 }
    end
    
    local magic = file.content:sub(1, 12)
    local is_image = (
        magic:sub(1,3) == "\xFF\xD8\xFF"                              or
        magic:sub(1,8) == "\x89PNG\r\n\x1A\n"                        or
        (magic:sub(1,4) == "RIFF" and magic:sub(9,12) == "WEBP")     or
        magic:sub(1,4) == "GIF8"
    )
    if not is_image then
        return { json = { error = "Unsupported image format." }, status = 415 }
    end

    local tmp_path = "/tmp/globo_" .. generate_token():sub(1, 16)
    local tmp_file = io.open(tmp_path, "wb")
    if not tmp_file then
        return { json = { error = "Failed to create temp file." }, status = 500 }
    end
    tmp_file:write(file.content)
    tmp_file:close()

    local img, err = magick.load_image(tmp_path)
    os.remove(tmp_path)

    if not img then
        return { json = { error = "Failed to load image: " .. (err or "unknown") }, status = 422 }
    end

    img:strip()

    local w = img:get_width()
    local h = img:get_height()
    if w > h then
        img:destroy()
        return { json = { error = "Image must be portrait (taller than wide)." }, status = 400 }
    end

    local new_h = math.floor(h * 1080 / w)
    img:resize(1080, new_h)

    local filename  = generate_token():sub(1, 24) .. ".webp"
    local save_path = "static/globos/" .. filename
    local url_path  = "/static/globos/" .. filename

    local ok, save_err = img:write(save_path)
    img:destroy()

    if not ok then
        return { json = { error = "Failed to save image: " .. (save_err or "unknown") }, status = 500 }
    end

    local rows = db.query(
        "INSERT INTO globos (user_id, image_path, lat, lon) VALUES (?, ?, ?, ?) RETURNING id, created_at, expires_at",
        self.current_user.id, url_path, lat, lon
    )

    if not rows or #rows == 0 then
        os.remove(save_path)
        return { json = { error = "Failed to insert globo." }, status = 500 }
    end

    local globo = rows[1]
    return { json = {
        id         = globo.id,
        image_path = url_path,
        lat        = lat,
        lon        = lon,
        created_at = globo.created_at,
        expires_at = globo.expires_at
    }, status = 201 }
end))

app:post("/api/globo/:id/rate", require_login(function(self)
    local globo_id = tonumber(self.params.id)
    local score    = tonumber(self.params.score)

    if not globo_id then
        return { json = { error = "Invalid globo id." }, status = 400 }
    end
    if not score or score < 0 or score > 5 or (score * 2) ~= math.floor(score * 2) then
        return { json = { error = "Score must be 0–5 in 0.5 increments." }, status = 400 }
    end

    local globo = db.select("* FROM globos WHERE id = ? AND expires_at > NOW()", globo_id)[1]
    if not globo then
        return { json = { error = "Globo not found or expired." }, status = 404 }
    end

    db.query([[
        INSERT INTO ratings (globo_id, user_id, score)
        VALUES (?, ?, ?)
        ON CONFLICT (globo_id, user_id) DO UPDATE SET score = EXCLUDED.score
    ]], globo_id, self.current_user.id, score)

    local avg_row = db.select("ROUND(AVG(score) * 2) / 2 AS avg_score FROM ratings WHERE globo_id = ?", globo_id)[1]
    local avg = tonumber(avg_row.avg_score) or 0

    if avg >= 4 and tonumber(globo.rating) < 4 then
        db.query([[
            UPDATE globos
            SET rating   = ?,
                lifetime = lifetime + INTERVAL '20 minutes'
            WHERE id = ?
        ]], avg, globo_id)
    else
        db.query("UPDATE globos SET rating = ? WHERE id = ?", avg, globo_id)
    end

    return { json = { globo_id = globo_id, new_rating = avg }, status = 200 }
end))

app:get("/api/globo/my", require_login(function(self)
    local globos = db.select("* FROM globos WHERE user_id = ? ORDER BY created_at DESC", self.current_user.id)

    local result = {}
    for _, globo in ipairs(globos) do
        table.insert(result, {
            id         = globo.id,
            image_path = globo.image_path,
            lat        = globo.lat,
            lon        = globo.lon,
            rating     = globo.rating,
            created_at = globo.created_at,
            expires_at = globo.expires_at
        })
    end

    return { json = result }
end))


app:get("/leaderboard", function(self)
  return { render = "leaderboard" }
end)

app:get("/about", function(self)
  return { render = "about" }
end)
    
app:get("/search", require_login(function(self)
  return { render = "search"}
end))

app:get("/challenge", require_login(function(self)
  return { render = "challenge"}
end))

app:get("/play", require_login(function(self)
  return { render = "play" }
end))


return app
