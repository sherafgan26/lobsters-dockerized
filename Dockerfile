# syntax=docker/dockerfile:1.7
#
# Production image for Lobsters. Two stages:
#   1. builder  — installs gems + precompiles assets
#   2. runtime  — slim image, just what's needed to run Puma
#
# Build:  docker build -t lobsters:latest .

ARG RUBY_VERSION=4.0.0

FROM ruby:${RUBY_VERSION}-slim AS builder

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_FROZEN=1 \
    RAILS_ENV=production

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libjemalloc-dev \
      libvips-dev \
      libmariadb-dev \
      pkg-config \
      git \
      curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile


FROM ruby:${RUBY_VERSION}-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    LD_PRELOAD=libjemalloc.so.2 \
    MALLOC_CONF=dirty_decay_ms:1000,narenas:2,background_thread:true

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      libjemalloc2 \
      libvips \
      libmariadb3 \
      curl \
      tzdata \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 1000 lobsters \
 && useradd --system --uid 1000 --gid 1000 --create-home --shell /bin/bash lobsters

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=lobsters:lobsters /app /app

USER lobsters

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:3000/up || exit 1

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
