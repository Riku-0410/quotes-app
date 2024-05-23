#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# 本番環境であればアセットをプリコンパイル

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
