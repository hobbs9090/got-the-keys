# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.7
ARG NODE_VERSION=22

FROM node:${NODE_VERSION}-bookworm-slim AS assets

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY app/assets ./app/assets
COPY app/javascript ./app/javascript
COPY vendor/assets ./vendor/assets

RUN npm run build

FROM ruby:${RUBY_VERSION}-slim AS app

WORKDIR /app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libsqlite3-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf /usr/local/bundle/cache/*.gem

COPY . .
COPY --from=assets /app/app/assets/builds ./app/assets/builds

RUN mkdir -p log tmp/pids tmp/cache tmp/sockets storage tmp/mails && \
    SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile

EXPOSE 3000

CMD ["./bin/container_start"]
