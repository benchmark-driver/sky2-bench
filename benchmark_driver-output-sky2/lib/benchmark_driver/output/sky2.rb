require 'benchmark_driver'
require 'yaml'
require 'fileutils'

class BenchmarkDriver::Output::Sky2
  # @param [Array<BenchmarkDriver::Metric>] metrics
  # @param [Array<BenchmarkDriver::Job>] jobs
  # @param [Array<BenchmarkDriver::Context>] contexts
  def initialize(metrics:, jobs:, contexts:)
    @jobs = jobs
    @contexts = contexts
    @metrics = metrics
    @result = StringIO.new
  end

  def with_warmup(&block)
    # noop
    block.call
  end

  def with_benchmark(&block)
    @with_benchmark = true
    doubly_puts "metrics_unit: #{@metrics.first.unit}"
    doubly_puts 'results:'

    result = block.call

    if ENV.key?('RESULT_YAML')
      @result.rewind
      merge_yaml(ENV['RESULT_YAML'], @result.read)
    else
      $stderr.puts "Missing $RESULT_YAML"
    end
    @result.close

    result
  ensure
    @with_benchmark = false
  end

  def with_job(job, &block)
    if @with_benchmark
      doubly_puts "  #{job.name.dump}:"
    end
    block.call
  end

  def with_context(context, &block)
    @context = context
    block.call
  end

  # @param [BenchmarkDriver::Metrics] metrics
  def report(result)
    if @with_benchmark
      doubly_puts("    #{@context.executable.name}: %6.3f" % result.values.values.first)
    end
  end

  private

  def doubly_puts(str)
    @result.puts(str)
    $stdout.puts(str)
  end

  def merge_yaml(path, yaml)
    if File.exist?(path)
      base_hash = YAML.load_file(path)
    else
      base_hash = { 'metrics_unit' => nil, 'results' => {} }
    end
    hash = YAML.load(yaml)

    base_hash['metrics_unit'] = hash['metrics_unit']

    hash['results'].each do |job, value_by_exec|
      unless base_hash['results'][job]
        base_hash['results'][job] = value_by_exec
        next
      end

      value_by_exec.each do |exec, value|
        base_hash['results'][job][exec] = value
      end
    end

    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, base_hash.to_yaml)
  end
end
