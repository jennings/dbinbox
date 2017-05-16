FROM        ubuntu:xenial

RUN         apt-get update \
            && apt-get install -y wget \
            && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > '/etc/apt/sources.list.d/pgdg.list' \
            && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
            && apt-get update               \
            && apt-get install -y           \
                build-essential             \
                ruby                        \
                ruby-dev                    \
                libsqlite3-dev              \
                libpq-dev                   \
                postgresql-server-dev-9.4   \
            && rm -rf /var/lib/apt/lists/*  \
            && wget --quiet -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
            && chmod +x /usr/local/bin/dumb-init \
            && /usr/bin/gem install bundler

WORKDIR     /app
COPY        ["Gemfile", "Gemfile.lock", "/app/"]
RUN         bundle install --deployment --without development

COPY        [".", "/app/"]

VOLUME      ["/data"]
EXPOSE      8000
ENV         DATABASE_URL=sqlite3:///data/dropzone.sqlite3
ENTRYPOINT  ["/usr/local/bin/dumb-init", "--"]
CMD         ["/usr/local/bin/bundle", "exec", "rackup", "--env", "deployment", "--host", "0.0.0.0", "--port", "8000"]
