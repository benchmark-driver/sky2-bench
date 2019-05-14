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
  :revisions, # Scheduling priority. Larger is built more.
  :vm_count,  # --repeat-count for VM executions
  :jit_count, # --repeat-count for JIT executions
  keyword_init: true,
)

pattern_configs = {
  'optcarrot/benchmark.yml'                    => BenchConfig.new(revisions: 5, vm_count: 2, jit_count: 4),
  'mjit-benchmarks/benchmarks/*.yml'           => BenchConfig.new(revisions: 2, vm_count: 1, jit_count: 1),
  'ruby-method-benchmarks/benchmarks/**/*.yml' => BenchConfig.new(revisions: 1, vm_count: 1, jit_count: 0),
}

ruby_revisions = Dir.glob(File.join(prefixes_dir, '*')).map(&File.method(:basename)).select { |f| f.match(/\A\h{10}\z/) }

pattern_configs.each do |pattern, config|
  target_revisions = [*ruby_revisions, *ruby_revisions.map { |v| "#{v} --jit" }]

  Dir.glob(File.join(definition_dir, pattern)).each do |definition_file|
    result_file = File.join(result_dir, definition_file.delete_prefix(definition_dir))

    # get versions built for all benchmarks in definition
    built_revisions =
      if File.exist?(result_file)
        YAML.load_file(result_file).fetch('results')
          .inject(target_revisions) { |built, (_benchmark, results)| built & results.keys }
      else
        []
      end

    # separate for different --repeat-count
    jit_versions, vm_versions = (target_revisions - built_revisions).partition { |v| v.end_with?(' --jit') }

    # schedule limited numbers for this run
    vm_versions  = vm_versions.sample(config.revisions)
    jit_versions = jit_versions.sample(config.revisions)

    # never make JIT-only or VM-only results
    vm_versions  |= jit_versions.map { |v| v.delete_suffix(' --jit') }
    jit_versions |= vm_versions.map { |v| "#{v} --jit" }

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
    benchmark_driver.call(vm_versions, config.vm_count)
    benchmark_driver.call(jit_versions, config.jit_count)
  end
end
