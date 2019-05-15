# snippet to generate partials

files = Dir.glob(File.expand_path('./benchmark/results/ruby-benchmarks/benchmarks/*.yml', __dir__)).sort.map(&File.method(:basename))
prefixes = files.map { |f| f.split(/_|\./).first }.uniq
prefixes.each do |prefix|
  File.write(File.expand_path("./source/benchmarks/ruby_core/commits/#{prefix}.html.haml"), "= partial 'shared', locals: { prefix: '#{prefix}' }")
  File.write(File.expand_path("./source/benchmarks/ruby_core/releases/#{prefix}.html.haml"), "= partial 'shared', locals: { prefix: '#{prefix}' }")
end

dirs = Dir.glob(File.expand_path('./benchmark/results/ruby-method-benchmarks/benchmarks/*', __dir__)).sort.map(&File.method(:basename))
dirs.each do |prefix|
  File.write(File.expand_path("./source/benchmarks/ruby_method/commits/#{prefix}.html.haml"), "= partial 'shared', locals: { prefix: '#{prefix}' }")
  File.write(File.expand_path("./source/benchmarks/ruby_method/releases/#{prefix}.html.haml"), "= partial 'shared', locals: { prefix: '#{prefix}' }")
end
