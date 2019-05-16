#!/bin/bash -eu
sky2_bench="$(cd "$(dirname $0)"; cd ..; pwd)"
sky2_result="$(cd "$sky2_bench"; cd ./sky2-result; pwd)"
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

# 5. Update sky2-result (cloned by sky2-infra)
git -C "$sky2_result" fetch origin master
git -C "$sky2_result" reset --hard remotes/origin/master

# 6. Generate descriptions.yml
env \
  BUILD_DESCRIPTIONS_PATH="${sky2_result}/descriptions.yml" \
  BUILD_DESCRIPTIONS_PREFIXES_DIR="/home/k0kubun/.rbenv/versions" \
  BUILD_DESCRIPTIONS_RUBY_REPOSITORY="$ruby_repo" \
  BUILD_DESCRIPTIONS_RUBY_REVISIONS="3000" \
  "${sky2_bench}/bin/build-descriptions.rb"

# 7. Update all release benchmark yamls
bundle check || bundle install -j24
env \
  RELEASE_BENCH_DEFINITION_DIR="${sky2_bench}/benchmark" \
  RELEASE_BENCH_PREFIXES_DIR="/home/k0kubun/.rbenv/versions" \
  RELEASE_BENCH_RESULT_DIR="${sky2_result}" \
  bundle exec "${sky2_bench}/bin/release-bench.rb"

# 8. Update benchmark yamls for some limited revisions
env \
  RELEASE_BENCH_DEFINITION_DIR="${sky2_bench}/benchmark" \
  RELEASE_BENCH_PREFIXES_DIR="/home/k0kubun/.rbenv/versions" \
  RELEASE_BENCH_RESULT_DIR="${sky2_result}" \
  bundle exec "${sky2_bench}/bin/commit-bench.rb"

# 9. Commit sky2-result
cd "$sky2_result"
git add .
if ! git diff-index --quiet HEAD --; then
  git commit -m "Benchmark result update by sky2-bench"
  git pull --rebase origin master
  git push origin master
fi
