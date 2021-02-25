#! /bin/bash

set -ex

export WEB_CONCURRENCY=$WEB_CONCURRENCY
export RAILS_MAX_THREADS=$RAILS_MAX_THREADS

bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:setup

exec "$@"
