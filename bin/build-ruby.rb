#!/usr/bin/env ruby
# Executed by bin/run
#
# Arguments:
#   $BUILD_RUBY_REVISIONS
#   $BUILD_RUBY_REPOSITORY

ruby_revisions = Integer(ENV.fetch('BUILD_RUBY_REVISIONS', '1000'))
ruby_repository = ENV.fetch('BUILD_RUBY_REPOSITORY')

puts "Hello build-ruby!"
