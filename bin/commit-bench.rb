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
  :revisions,  # Scheduling priority. Larger is built more.
  :vm_count,   # --repeat-count for VM executions
  :jit_count,  # --repeat-count for JIT executions
  :yjit_count, # --repeat-count for YJIT executions
  :timeout,    # --timeout
  keyword_init: true,
)

# revisions: scheduling frequency
# vm_count, jit_count, yjit_count: --repeat-count
pattern_configs = {
  'optcarrot/benchmark.yml'      => BenchConfig.new(revisions: 4, vm_count: 4, jit_count: 4, yjit_count: 4, timeout:  60),
  'optcarrot/benchmark_3000.yml' => BenchConfig.new(revisions: 2, vm_count: 2, jit_count: 2, yjit_count: 2, timeout: 360),
  'rubykon-benchmark.yml'        => BenchConfig.new(revisions: 1, vm_count: 1, jit_count: 1, yjit_count: 1, timeout:  60),
}

ruby_revisions = Dir.glob(File.join(prefixes_dir, '*')).map(&File.method(:basename)).select { |f| f.match(/\A\h{10}\z/) }
descriptions = YAML.safe_load(File.read(File.join(result_dir, 'descriptions.yml'))).fetch('commits')

pattern_configs.each do |pattern, config|
  target_revisions = [*ruby_revisions, *ruby_revisions.map { |v| "#{v} --jit" }, *ruby_revisions.map { |v| "#{v} --yjit" }]

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
    jit_versions, other_versions = (target_revisions - built_revisions).partition { |v| v.end_with?(' --jit') }
    yjit_versions, vm_versions = other_versions.partition { |v| v.end_with?(' --yjit') }

    # schedule limited numbers for this run
    build_scheduler = proc do |versions|
      next [] if config.revisions == 0
      latest = versions.max_by { |v| descriptions.fetch(v, '') }
      [latest, *versions.sample(config.revisions - 1)].compact
    end
    vm_versions   = build_scheduler.call(vm_versions)
    jit_versions  = build_scheduler.call(jit_versions)
    yjit_versions = build_scheduler.call(yjit_versions)

    # never make JIT-only or VM-only results
    vm_versions   |= jit_versions.map { |v| v.delete_suffix(' --jit') }
    vm_versions   |= yjit_versions.map { |v| v.delete_suffix(' --yjit') }
    jit_versions  |= vm_versions.map { |v| "#{v} --jit" }
    yjit_versions |= vm_versions.map { |v| "#{v} --yjit" }

    # run benchmarks
    benchmark_driver = proc do |versions, repeat_count|
      next if versions.empty? || repeat_count == 0
      versions = versions.map do |version|
        segments = version.split(' ')
        segments[1, 0] = '--disable=yjit'
        "#{version}::#{segments.join(' ')}"
      end
      cmd = [
        'benchmark-driver', definition_file, '--rbenv', versions.map { |v| v.gsub(/--jit/, '--mjit') }.join(';'),
        '--repeat-count', repeat_count.to_s, '--output', 'sky2', '--timeout', config.timeout.to_s,
      ]
      puts "+ #{cmd.shelljoin}"
      unless system({ 'RESULT_YAML' => result_file }, *cmd) # Keep running even on failure of each benchmark execution
        puts "Failed to execute: #{cmd.shelljoin}"
      end
    end
    benchmark_driver.call(vm_versions, config.vm_count)
    benchmark_driver.call(jit_versions, config.jit_count)
    benchmark_driver.call(yjit_versions, config.yjit_count)
  end
end
