#!/usr/bin/env ruby
# Executed by bin/sky2-bench.sh
require 'yaml'
require 'shellwords'

# Arguments:
#   $RELEASE_BENCH_DEFINITION_DIR
#   $RELEASE_BENCH_PREFIXES_DIR
#   $RELEASE_BENCH_RESULT_DIR
definition_dir = ENV.fetch('RELEASE_BENCH_DEFINITION_DIR')
prefixes_dir   = ENV.fetch('RELEASE_BENCH_PREFIXES_DIR')
result_dir     = ENV.fetch('RELEASE_BENCH_RESULT_DIR')

BenchConfig = Struct.new(
  :vm_count,  # --repeat-count for VM executions
  :jit_count, # --repeat-count for JIT executions
  keyword_init: true,
)

pattern_configs = {
  'mjit-benchmarks/benchmarks/*.yml'           => BenchConfig.new(vm_count: 1, jit_count: 1),
  'optcarrot/benchmark.yml'                    => BenchConfig.new(vm_count: 2, jit_count: 4),
  'ruby-method-benchmarks/benchmarks/**/*.yml' => BenchConfig.new(vm_count: 1, jit_count: 0),
}

ruby_versions = Dir.glob(File.join(prefixes_dir, '*')).map(&File.method(:basename)).reject { |f| f.match(/\A\h{10}\z/) }

pattern_configs.each do |pattern, config|
  Dir.glob(File.join(definition_dir, pattern)).each do |definition_file|
    result_file = File.join(result_dir, definition_file.delete_prefix(definition_dir))

    # rule out old rubies by required_ruby_version
    required_versions = Array(YAML.load_file(definition_file).fetch('benchmark', [])).map { |b| b.is_a?(Hash) && b['required_ruby_version'] }.compact
    runnable_versions =
      if File.exist?(result_file)
        ruby_versions.select { |v| required_versions.all? { |req| Gem::Version.new(v) >= Gem::Version.new(req) } } # be conservative for the second run
      else
        ruby_versions # run everything for the first run
      end
    target_versions = [
      *runnable_versions,
      *runnable_versions.select { |v| Gem::Version.new(v) >= Gem::Version.new('2.6.0') }.map { |v| "#{v} --jit" },
    ]

    # get versions built for all benchmarks in definition
    built_versions =
      if File.exist?(result_file)
        YAML.load_file(result_file).fetch('results')
          .inject(target_versions) { |built, (_benchmark, results)| built & results.keys }
      else
        []
      end

    # separate for different --repeat-count
    jit_versions, vm_versions = (target_versions - built_versions).partition { |v| v.end_with?(' --jit') }

    # run benchmarks
    benchmark_driver = proc do |versions, repeat_count|
      next if versions.empty? || repeat_count == 0
      cmd = [
        'benchmark-driver', definition_file, '--rbenv', versions.join(';'),
        '--repeat-count', repeat_count.to_s, '--output', 'sky2', '--timeout', '60',
      ]
      puts "+ #{cmd.shelljoin}"
      unless system({ 'RESULT_YAML' => result_file }, *cmd) # Keep running even on failure of each benchmark execution
        puts "Failed to execute: #{cmd.shelljoin}"
      end
    end
    benchmark_driver.call(vm_versions.sort, config.vm_count)
    benchmark_driver.call(jit_versions.sort, config.jit_count)
  end
end
