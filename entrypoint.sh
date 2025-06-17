#!/bin/bash
set -e

export BUNDLE_PATH=/rails/vendor/bundle

# Install missing gems
bundle check || bundle install

# Then run the main command
exec "$@"
