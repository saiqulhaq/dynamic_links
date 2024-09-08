require_relative 'lib/dynamic_links/version'

Gem::Specification.new do |spec|
  spec.name        = 'dynamic_links'
  spec.version     = DynamicLinks::VERSION
  spec.authors     = ['Saiqul Haq']
  spec.email       = ['saiqulhaq@gmail.com']
  spec.homepage    = 'https://saiqulhaq.id/dynamic_links'
  spec.summary     = 'Alternative to Firebase Dynamic Links feature'
  spec.description = 'Rails engine to shorten any URL with custom domain.'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/saiqulhaq/dynamic_links'
  spec.metadata['changelog_uri'] = 'https://github.com/saiqulhaq/dynamic_links/blob/master/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 5'
  spec.add_development_dependency 'nanoid', '~> 2.0'
  spec.add_development_dependency 'redis', '>= 4'
  spec.add_development_dependency 'annotate'
  spec.add_development_dependency 'dotenv-rails'
  spec.add_development_dependency 'ahoy_matey'
end
