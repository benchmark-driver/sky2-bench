# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

set :haml, format: :html5

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def github_link(repository)
    link_to repository, "https://github.com/#{repository}"
  end

  def result_path(path)
    File.join(ENV.fetch('RESULT_PATH'), path)
  end

  def fetch_results(path, releases: true)
    results = { 'descriptions' => {}, 'results' => {} }

    Dir.glob(result_path(path)).sort.each do |yaml|
      original = YAML.load_file(yaml)
      results['metrics_unit'] = original.fetch('metrics_unit')

      # original['descriptions'].each do |version, description|
      #   if (releases && !revision?(version)) || (!releases && revision?(version))
      #     results['descriptions'][version] = description
      #   end
      # end

      original['results'].each do |job, value_by_version|
        value_by_version.each do |version, value|
          if (releases && !revision?(version)) || (!releases && revision?(version))
            results['results'][job] ||= {}
            results['results'][job][version] = value
          end
        end
      end
    end

    results
  end

  private

  def revision?(name)
    name.match?(/\A\h{10}( --jit)?\z/)
  end
end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end
