require_relative 'lib/dynamic_links_analytics/version'

Gem::Specification.new do |spec|
  spec.name        = 'dynamic_links_analytics'
  spec.version     = DynamicLinksAnalytics::VERSION
  spec.authors     = ['Dynamic Links Team']
  spec.email       = ['team@dynamiclinks.com']
  spec.homepage    = 'https://github.com/saiqulhaq/dynamic_links'
  spec.summary     = 'Analytics engine for Dynamic Links'
  spec.description = 'Provides analytics capabilities for the Dynamic Links engine, tracking click events and storing metrics in PostgreSQL'
  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/saiqulhaq/dynamic_links/tree/main/engines/dynamic_links_analytics'
  spec.metadata['changelog_uri'] = 'https://github.com/saiqulhaq/dynamic_links/blob/main/engines/dynamic_links_analytics/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'pg', '>= 1.1'
  spec.add_dependency 'rails', '>= 7.0.0'

  spec.add_development_dependency 'rspec-rails'
end
