#!/usr/bin/env ruby
# Executed by bin/run

# Arguments:
#   $BUILD_RUBY_REVISIONS
#   $BUILD_RUBY_REPOSITORY
build_ruby_revisions = Integer(ENV.fetch('BUILD_RUBY_REVISIONS', '1000'))
build_ruby_repository = ENV.fetch('BUILD_RUBY_REPOSITORY')

# older first
latest_revisions = IO.popen(
  ['git', 'log', '--pretty=format:"%h"', '--abbrev=10', '--reverse', '--topo-order', '-n', build_ruby_revisions.to_s], &:read)
  .lines.map(&:strip)

system('git', 'show', latest_revisions.first)
