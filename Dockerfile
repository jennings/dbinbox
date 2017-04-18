FROM        ubuntu:xenial

WORKDIR     /app
VOLUME      ["/data"]
EXPOSE      8000
ENV         DATABASE_URL=sqlite3:///data/dropzone.sqlite3
ENTRYPOINT  ["/usr/local/bin/bundle", "exec"]
CMD         ["rackup", "--env", "deployment", "--host", "0.0.0.0", "--port", "8000"]

# The commented lines add Postgres support, but inflate the image size
RUN         apt-get update \
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
            && rm -rf /var/lib/apt/lists/*  \
            && /usr/bin/gem install bundler

COPY        ["Gemfile", "Gemfile.lock", "/app/"]
RUN         bundle install --deployment --without postgres development

COPY        [".", "/app/"]
