#!/usr/bin/env ruby
# Executed by bin/run
require 'shellwords'

# Arguments:
#   $BUILD_RUBY_BRANCH
#   $BUILD_RUBY_REVISIONS
#   $BUILD_RUBY_REPOSITORY
#   $BUILD_RUBY_PREFIXES_DIR
build_ruby_revisions = Integer(ENV.fetch('BUILD_RUBY_REVISIONS', '1000'))
build_ruby_repository = ENV.fetch('BUILD_RUBY_REPOSITORY')

RubyBuilder = Module.new
class << RubyBuilder
  def branch
    @branch ||= ENV.fetch('BUILD_RUBY_BRANCH')
  end

  def prefixes_dir
    @prefixes_dir ||= ENV.fetch('BUILD_RUBY_PREFIXES_DIR')
  end

  # Assumes build_ruby_repository is checked out
  def install_revision(revision)
    prefix = File.join(prefixes_dir, revision)
    execute('git', 'reset', '--hard', revision) && (try_make(prefix) || clean_make(prefix))
  end

  def uninstall_revision(revision)
    execute('rm', '-rf', File.join(prefixes_dir, revision), exception: true)
  end

  # #system with logs.
  def execute(*args, exception: false)
    puts "+ #{args.shelljoin}"
    system(*args, exception: exception)
  end

  private

  def try_make(prefix)
    execute("./configure --prefix=#{prefix.shellescape} --disable-install-doc") && execute('make', '-j4', 'all', 'install')
  end

  def clean_make(prefix)
    execute('make', 'clean')
    execute('autoconf')
    try_make(prefix)
  end
end

Dir.chdir(build_ruby_repository) do
  RubyBuilder.execute('git', 'fetch', 'origin', RubyBuilder.branch, exception: true)
  RubyBuilder.execute('git', 'reset', '--hard', "remotes/origin/#{RubyBuilder.branch}", exception: true)

  latest_revisions = IO.popen(
    ['git', 'log', '--pretty=format:%h', '--abbrev=10', '--reverse', '--topo-order', '-n', build_ruby_revisions.to_s], &:read)
    .lines.map(&:strip) # older first
  built_revisions = Dir.glob(File.join(RubyBuilder.prefixes_dir, '*')).map(&File.method(:basename)).select { |v| v.match(/\A\h{10}\z/) }

  # GC obsoleted revisions
  if built_revisions.size > build_ruby_revisions
    (built_revisions - latest_revisions).each do |obsolete_revision|
      RubyBuilder.uninstall_revision(obsolete_revision)
    end
  end

  latest_built_revision = latest_revisions.reverse.find { |rev| built_revisions.include?(rev) }
  revisions_to_build =
    if latest_built_revision
      latest_revisions[(latest_revisions.index(latest_built_revision) + 1)..]
    else
      latest_revisions
    end

  revisions_to_build.each do |revision|
    RubyBuilder.install_revision(revision)
    break # DEBUG
  end
end
