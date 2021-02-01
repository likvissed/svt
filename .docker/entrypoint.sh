#! /bin/bash

set -e

if [[ "$3" = "rails" ]]
then
  # Packages
  bundle check || bundle install
  yarn install

  # Database
  bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup

  if [[ "$4" = "s" || "$4" == "server" ]]; then rm -f /app/tmp/pids/server.pid; fi
fi

exec "$@"
