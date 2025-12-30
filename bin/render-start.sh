#!/usr/bin/env bash
# exit on error
set -o errexit

# Ruby on Rails
exec bundle exec rails server -e "${RAILS_ENV:-production}" -b 0.0.0.0 -p "${PORT:-3000}"
