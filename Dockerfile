FROM    ubuntu:xenial

# Add the Postgres apt repository first
RUN     apt-get update \
        # && apt-get install -y wget \
        # && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > '/etc/apt/sources.list.d/pgdg.list' \
        # && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
        # && apt-get update               \
        && apt-get install -y           \
            build-essential             \
            ruby                        \
            ruby-dev                    \
            libsqlite3-dev              \
            # libpq-dev                   \
            # postgresql-server-dev-9.4   \
        && apt-get autoremove           \
        && apt-get autoclean            \
        && /usr/bin/gem install bundler

WORKDIR /app

COPY    ["Gemfile", "Gemfile.lock", "/app/"]
RUN     bundle install --deployment --without postgres development

COPY    [".", "/app/"]

VOLUME  ["/data"]

EXPOSE  8000
ENV     DATABASE_URL=sqlite3:///data/dbinbox.sqlite3

ENTRYPOINT  ["/usr/local/bin/bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "8000"]
