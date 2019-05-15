#!/bin/bash -eu
sky2_viewer="$(cd "$(dirname $0)"; cd ..; pwd)"

# Usage:
#   build.sh [result path] [pages path]
result_path="$1"
pages_path="$2"

# install execjs runtime
set -x
apt-get update && apt-get install -y nodejs

# build viewer
cd "$sky2_viewer"
bundle install -j4
ln -s "$pages_path" build
env \
  RESULT_PATH="$result_path" \
  TZ="Asia/Tokyo" \
  bundle exec middleman build

if [[ "$WERCKER_GIT_BRANCH" = "master" ]]; then
  result_revision="$(git -C "$result_path" rev-parse HEAD)"

  # Commit changes
  cd "$pages_path"
  git add .
  if ! git diff-index --quiet HEAD --; then
    git config --global user.email "sky2-viewer@benchmark-driver.github.io"
    git config --global user.name "sky2-viewer"
    git commit -m "Automatic deployment by Wercker

See: https://github.com/benchmark-driver/sky2-result/commit/${result_revision}"
    git push origin master
  fi
fi
