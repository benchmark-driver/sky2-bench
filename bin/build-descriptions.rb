#!/usr/bin/env ruby
# Executed by bin/sky2-bench.sh
# This file creates the following YAML:
#
# ```
# releases:
#   2.3.6: ruby 2.3.6p384 (2017-12-14 revision 61254) [x86_64-linux]
#   2.4.3: ruby 2.4.3p205 (2017-12-14 revision 61247) [x86_64-linux]
#   2.5.0: ruby 2.5.0p0 (2017-12-25 revision 61468) [x86_64-linux]
# commits:
#   ffec546b0e: ruby 2.7.0dev (2019-03-09 trunk 67201) [x86_64-linux]
#   ffec546b0e --jit: ruby 2.7.0dev (2019-03-09 trunk 67201) +JIT [x86_64-linux]
#   ffc93316c8: ruby 2.7.0dev (2019-04-21 trunk 67658) [x86_64-linux]
#   ffc93316c8 --jit: ruby 2.7.0dev (2019-04-21 trunk 67658) +JIT [x86_64-linux]
# ```
#
# NOTE: The Hash values are supposed to be ordered by a version number or a commit date.
require 'yaml'

# Arguments:
#   $BUILD_DESCRIPTIONS_PATH
#   $BUILD_DESCRIPTIONS_PREFIXES_DIR
#   $BUILD_DESCRIPTIONS_RUBY_REPOSITORY
#   $BUILD_DESCRIPTIONS_RUBY_REVISIONS
descriptions_path = ENV.fetch('BUILD_DESCRIPTIONS_PATH')
prefixes_dir = ENV.fetch('BUILD_DESCRIPTIONS_PREFIXES_DIR')
ruby_repository = ENV.fetch('BUILD_DESCRIPTIONS_RUBY_REPOSITORY')
ruby_revisions = ENV.fetch('BUILD_DESCRIPTIONS_RUBY_REVISIONS')

releases = Dir.glob(File.join(prefixes_dir, '*')).map(&File.method(:basename)).reject { |f| f.match(/\A\h{10}\z/) }
release_descriptions = releases.map { |r| Gem::Version.new(r) }.sort.flat_map { |v|
  [
    [v.to_s, IO.popen([File.join(prefixes_dir, v.to_s, 'bin/ruby'), '-v'], &:read).rstrip],
    *([["#{v} --jit", IO.popen([File.join(prefixes_dir, v.to_s, 'bin/ruby'), '--jit', '-v'], &:read).rstrip]] if v >= Gem::Version.new('2.6.0')),
  ]
}

built_commits = Dir.glob(File.join(prefixes_dir, '*')).map(&File.method(:basename)).select { |f| f.match(/\A\h{10}\z/) }
sorted_commits = IO.popen([
  'git', '-C', ruby_repository, 'log', '--pretty=format:%h', '--abbrev=10', '--reverse',
  '--topo-order', '-n', ruby_revisions.to_s
], &:read).lines.map(&:strip) # older first
commits_descriptions = sorted_commits.select { |r| built_commits.include?(r) }.flat_map { |r|
  [
    [r, IO.popen([File.join(prefixes_dir, r, 'bin/ruby'), '-v'], &:read).rstrip],
    ["#{r} --jit", IO.popen([File.join(prefixes_dir, r, 'bin/ruby'), '--jit', '-v'], &:read).rstrip],
  ]
}

File.write(descriptions_path, {
  'releases' => Hash[release_descriptions],
  'commits' => Hash[commits_descriptions],
}.to_yaml)
