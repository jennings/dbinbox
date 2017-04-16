Dropzone
========

[![Docker Build Status](https://img.shields.io/docker/build/jennings/dropzone.svg)](https://hub.docker.com/r/jennings/dropzone)

An inbox for your Dropbox. For the original hosted version, see:
[dbinbox](https://dbinbox.com).

By visiting your personal Dropzone URL, visitors will be able to upload files
straight into a special inbox folder in your Dropbox.

Thanks to [Christian Genco](https://github.com/christiangenco) for the bulk of
this code. I renamed this repo to "Dropzone" because it didn't feel right using
his business' name.

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

This will start dbinbox running in a Vagrant VM. The app should be available at
**`http://localhost:9393`**

The app should automatically reload each time you edit a file.


## Deploying a private instance

### Self-hosted

```bash
# for Postgres
bundle install --without sqlite development

# for SQLite
bundle install --without postgres development

bundle exec rackup --host 0.0.0.0 --port 3000
```

### Heroku

To deploy on Heroku's Cedar stack:

1. Create a new app and add the heroku-postgresql addon:

        heroku apps:create
        heroku addons:add heroku-postgresql

2. Set BUNDLE_WITHOUT to ignore the sqlite dependencies (this requires
   enabling the user_env_compile feature flag):

        heroku labs:enable user-env-compile
        heroku config:set BUNDLE_WITHOUT="development:test:sqlite"

3. Configure your Dropbox key and secret

        heroku config:set DROPBOX_KEY="my-dropbox-key"
        heroku config:set DROPBOX_SECRET="my-dropbox-secret"

4. Push!

        git push heroku master
