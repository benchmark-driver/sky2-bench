#!/usr/bin/env ruby
# Executed by bin/run

# Arguments:
#   $BUILD_RUBY_REVISIONS
#   $BUILD_RUBY_REPOSITORY
#   $BUILD_RUBY_PREFIXES_DIR
build_ruby_revisions = Integer(ENV.fetch('BUILD_RUBY_REVISIONS', '1000'))
build_ruby_repository = ENV.fetch('BUILD_RUBY_REPOSITORY')
build_ruby_prefixes_dir = ENV.fetch('BUILD_RUBY_PREFIXES_DIR')

# Assumes build_ruby_repository is checked out
RubyBuilder = Module.new
class << RubyBuilder
  def build_revision(revision)
  end
end

Dir.chdir(build_ruby_repository) do
  latest_revisions = IO.popen(
    ['git', 'log', '--pretty=format:%h', '--abbrev=10', '--reverse', '--topo-order', '-n', build_ruby_revisions.to_s], &:read)
    .lines.map(&:strip) # older first
  built_revisions = Dir.glob(File.join(build_ruby_prefixes_dir, '*')).map(&File.method(:basename)).select { |v| v.match(/\A\h{10}\z/) }

  system('git', 'show', latest_revisions.first)
  p built_revisions
end
