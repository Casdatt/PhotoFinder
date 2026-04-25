# PhotoFinder



# PhotoFinder
## How to run
This guide assumes you are using Ubuntu

### 1. Install OpenResty
Follow the official OpenResty installation guide for Ubuntu:
https://openresty.org/en/linux-packages.html#ubuntu

### 2. Install Lapis and bcrypt
```
sudo luarocks install lapis
sudo luarocks install bcrypt
```

### 3. Install PostgreSQL
```
sudo apt install postgresql
```

### 4. Start PostgreSQL and enable it on boot

```
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

### 5. Create the database

```
psql postgres -c "CREATE DATABASE photofind;"
```

Then update your `config.lua` with the database name, user, and password if needed.

### 6. Run the app

```
lapis server
```

Visit `http://localhost:8080` in your browser.
