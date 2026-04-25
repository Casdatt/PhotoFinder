# PhotoFinder
  Go to <strong>Search</strong> and you will receive a photo taken somewhere nearby. Your goal is to physically find the location where that photo was taken. The closer you get, the more credits you earn.

  Credits let you upload your own photos for other players to find. The better rated your photo, the longer it stays alive. And the more credits you get.


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


### EXTRA 7. get it on the internet with ngrok
As an extra ( what we did ) you can get a ngrok account and get the project to the world wide web. For more information check out: https://medium.com/@tilakpat/deploy-your-hackathon-site-server-in-less-than-a-minute-4cbc866a257f

