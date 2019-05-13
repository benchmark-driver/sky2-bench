#!/usr/bin/env ruby
# Executed by bin/run

# Arguments:
#   $BUILD_RUBY_REVISIONS
#   $BUILD_RUBY_REPOSITORY
#   $BUILD_RUBY_PREFIXES_DIR
build_ruby_revisions = Integer(ENV.fetch('BUILD_RUBY_REVISIONS', '1000'))
build_ruby_repository = ENV.fetch('BUILD_RUBY_REPOSITORY')

RubyBuilder = Module.new
class << RubyBuilder
  def prefixes_dir
    @prefixes_dir ||= ENV.fetch('BUILD_RUBY_PREFIXES_DIR')
  end

  # Assumes build_ruby_repository is checked out
  def install_revision(revision)
  end

  def uninstall_revision(revision)
    system('rm', '-rf', File.join(prefixes_dir, revision), exception: true)
  end
end

Dir.chdir(build_ruby_repository) do
  latest_revisions = IO.popen(
    ['git', 'log', '--pretty=format:%h', '--abbrev=10', '--reverse', '--topo-order', '-n', build_ruby_revisions.to_s], &:read)
    .lines.map(&:strip) # older first
  built_revisions = Dir.glob(File.join(RubyBuilder.prefixes_dir, '*')).map(&File.method(:basename)).select { |v| v.match(/\A\h{10}\z/) }

  # GC obsoleted revisions
  (built_revisions - latest_revisions).each do |obsolete_revision|
    RubyBuilder.uninstall_revision(obsolete_revision)
  end

  latest_built_revision = latest_revisions.reverse.find { |rev| !built_revisions.include?(rev) }
  revisions_to_build =
    if latest_built_revision
      latest_revisions[(latest_revisions.index(latest_built_revision) + 1)..]
    else
      latest_revisions
    end

  revisions_to_build.each do |revision|
    RubyBuilder.install_revision(revision)
    puts "Build!: #{revision}"
    break
  end
end
