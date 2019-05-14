#!/bin/bash -eu
sky2_bench="$(cd "$(dirname $0)"; cd ..; pwd)"
ruby_repo="$(cd "$sky2_bench"; cd ../ruby; pwd)"

# 0. systemd-timer updates this repository to latest master

# 1. Setup rbenv (reflect .ruby-version)
eval "$(rbenv init -)"
set -x

# 2. Update benchmark definitions
cd "$sky2_bench"
git submodule init && git submodule update

# 3. Install ruby releases
# delegated to sky2-infra for now

# 4. Build latest 1000 ruby revisions
env \
  BUILD_RUBY_BRANCH=trunk \
  BUILD_RUBY_REVISIONS=1000 \
  BUILD_RUBY_REPOSITORY="$ruby_repo" \
  BUILD_RUBY_PREFIXES_DIR="/home/k0kubun/.rbenv/versions" \
  "${sky2_bench}/bin/build-ruby.rb"

# 5. Update sky2-result
# ...

# 6. Update all release benchmark yamls
# "${sky2_bench}/bin/release-bench.rb"

# 7. Update benchmark yamls for the oldest revision
# "${sky2_bench}/bin/commit-bench.rb"

# 8. Commit sky2-result
# git add benchmark/results
# if ! git diff-index --quiet HEAD --; then
#   git commit -m "Benchmark result update by skybench"
#   git pull --rebase origin master
#   git push origin master
# fi