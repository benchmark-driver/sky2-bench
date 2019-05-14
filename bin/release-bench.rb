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
  target_versions = [
    *(ruby_versions if config.vm_count > 0),
    *(ruby_versions.map { |v| "#{v} --jit" } if config.jit_count > 0),
  ]

  Dir.glob(File.join(definition_dir, pattern)).each do |definition_file|
    result_file = File.join(result_dir, definition_file.delete_prefix(definition_dir))

    # get versions built for all benchmarks in definition
    built_versions =
      if File.exist?(result_file)
        YAML.load_file(result_file).fetch('results')
          .inject(target_versions) { |built, (_benchmark, results)| built & results.keys }
      else
        []
      end

    # run benchmarks
    (target_versions - built_versions).each do |version|
      cmd = [
        'benchmark-driver', definition_file, '--rbenv', version, '--output', 'sky2',
        '--repeat-count', (version.end_with?(' --jit') ? config.jit_count : config.vm_count).to_s,
      ]
      puts "+ #{cmd.shelljoin}"
      unless system({ 'RESULT_YAML' => result_file }, *cmd) # Keep running even on failure of each benchmark execution
        puts "Failed to execute: #{cmd.shelljoin}"
      end
    end
  end
end
