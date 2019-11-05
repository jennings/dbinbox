Dropzone
========

[![Docker Build Status](https://img.shields.io/docker/build/jennings/dropzone.svg)](https://hub.docker.com/r/jennings/dropzone)

An inbox for your Dropbox. For the original hosted version, see:
[Fileinbox](https://fileinbox.com/).

By visiting your personal Dropzone URL, visitors will be able to upload files
straight into a special inbox folder in your Dropbox.

Thanks to [Christian Genco](https://github.com/christiangenco) for the bulk of
this code. I renamed this project to "Dropzone" because it didn't feel right using
his business' former name "DBinbox".

Uses:

* https://github.com/blueimp/jQuery-File-Upload
* http://datamapper.org/


## Development

Create your own [Dropbox app](https://www.dropbox.com/developers/apps), then
create a `.env` file and fill in your app's key and secret:

    cp .env.sample .env
    nano .env

Install [Vagrant](https://www.vagrantup.com/), then run:

    vagrant up

This will start Dropzone running in a Vagrant VM. The app should be available at
**`http://localhost:9393`**

The app should automatically reload each time you edit a file.


## Deploying a private instance

### Self-hosted

There's a [Docker image](https://hub.docker.com/r/jennings/dropzone/) you can
use. The service in the container listens on port 8000 and stores its data in
`/data`:

```bash
cp .env.sample /path/to/environment_variables.txt
nano /path/to/environment_variables.txt

# Create and start the container
docker container run -d --name dropzone                             \
                     -p 8000:8000                                   \
                     -v /path/to/data:/data                         \
                     --env-file /path/to/environment_variables.txt  \
                     --restart unless-stopped                       \
                     jennings/dropzone
```

The environment variable `DATABASE_URL` controls where user data is stored. It
defaults to:

    sqlite3:///data/dropzone.sqlite3

But if you expect to be hosting thousands of users (?), you can change it to a
Postgres URL like:

    postgres://hostname/database?user=myuser&password=mysecret

You probably want HTTPS, so this can be run behind a [reverse
proxy](#reverse-proxy-with-nginx).


### Self-hosted (without Docker)

```bash
# for Postgres
bundle install --deployment --without sqlite development

# for SQLite
bundle install --deployment --without postgres development

# Get these values from developer.dropbox.com
export DROPBOX_KEY="my-dropbox-key"
export DROPBOX_SECRET="my-dropbox-secret"

bundle exec rackup --host 0.0.0.0 --port 8000

```

Again, you should probably run this behind a [reverse
proxy](#reverse-proxy-with-nginx).


### Heroku

To deploy on Heroku's Cedar stack:

1. Create a new app and add the heroku-postgresql addon:

        heroku apps:create
        heroku addons:add heroku-postgresql

2. Set BUNDLE_WITHOUT to ignore the sqlite dependencies (this requires
   enabling the user_env_compile feature flag):

        heroku config:set BUNDLE_WITHOUT="development:test:sqlite"

3. Configure your Dropbox key and secret

        heroku config:set DROPBOX_KEY="my-dropbox-key"
        heroku config:set DROPBOX_SECRET="my-dropbox-secret"

4. Push!

        git push heroku master

## Reverse proxy with nginx

You probably want HTTPS, so you'll need a reverse proxy to terminate the TLS
(SSL) connection.

Don't have a favorite reverse proxy server? nginx is pretty easy to configure.
Here's an example nginx.conf script that's ready to use. This config expects
you to have used [Certbot](https://certbot.eff.org/) to install a free
certificate from [Let's Encrypt](https://letsencrypt.org/).

```conf
events {
}

http {

    upstream dropzone {
        # Change this if you're running dropzone on another server
        server localhost:8000;
    }

    server {
        listen      80;
        listen      [::]:80;

        location / {
            return 301 https://$host$request_uri;
        }

        # This is so Certbot can use the webroot authenticator
        location /.well-known/ {
            root /usr/share/nginx/html/.well-known;
        }
    }

    server {
        listen              443 ssl;
        listen              [::]:443 ssl;

        # Change these lines so they contain your real domain name
        server_name         MY-DOMAIN.EXAMPLE.COM;
        ssl_certificate     /etc/letsencrypt/live/MY-DOMAIN.EXAMPLE.COM/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/MY-DOMAIN.EXAMPLE.COM/privkey.pem;

        location / {
            proxy_pass          http://dropzone;
            proxy_http_version  1.1;
            proxy_set_header    X-Real-IP          $remote_addr;
            proxy_set_header    Host               $host;
            proxy_set_header    X-Forwarded-For    $proxy_add_x_forwarded_for;
            proxy_set_header    X-Forwarded-Proto  https;
        }
    }
}
```
