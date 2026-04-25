# PhotoFinder



## How to run
This guide assumes you are using Ubuntu
### 1. Install PostgreSQL

```bash
sudo apt install postgresql
```

### 2. Start PostgreSQL and enable it on boot

```bash
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

### 3. Create the database

```bash
psql postgres -c "CREATE DATABASE photofind;"
```

Then update your `config.lua` with the database name, user, and password if needed.

### 4. Run the app

```bash
lapis server
```

Visit `http://localhost:8080` in your browser.
