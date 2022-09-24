# frozen_string_literal: true

require_relative 'lib/formalism/version'

Gem::Specification.new do |spec|
	spec.name          = 'formalism'
	spec.version       = Formalism::VERSION
	spec.summary       = 'Forms with input data validations and nesting'
	spec.description   = <<~DESC
		Simple actions and complex forms with validations, nesting, etc.
	DESC
	spec.authors       = ['Alexander Popov']
	spec.email         = 'alex.wayfer@gmail.com'
	spec.license       = 'MIT'

	github_uri = "https://github.com/AlexWayfer/#{spec.name}"

	spec.homepage = github_uri

	spec.metadata = {
		'bug_tracker_uri' => "#{github_uri}/issues",
		'changelog_uri' => "#{github_uri}/blob/v#{spec.version}/CHANGELOG.md",
		'documentation_uri' => "http://www.rubydoc.info/gems/#{spec.name}/#{spec.version}",
		'homepage_uri' => spec.homepage,
		'rubygems_mfa_required' => 'true',
		'source_code_uri' => github_uri,
		'wiki_uri' => "#{github_uri}/wiki"
	}

	spec.files = Dir['lib/**/*.rb', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']

	spec.required_ruby_version = '>= 2.6', '< 4'

	spec.add_dependency 'gorilla_patch', '>= 4', '< 6'
	spec.add_dependency 'module_methods', '~> 0.1.0'

	spec.add_development_dependency 'pry-byebug', '~> 3.9'

	spec.add_development_dependency 'bundler', '~> 2.0'
	spec.add_development_dependency 'bundler-audit', '~> 0.9.0'

	spec.add_development_dependency 'gem_toys', '~> 0.12.1'
	spec.add_development_dependency 'toys', '~> 0.13.0'

	spec.add_development_dependency 'rspec', '~> 3.9'
	spec.add_development_dependency 'simplecov', '~> 0.21.2'
	spec.add_development_dependency 'simplecov-cobertura', '~> 2.1'

	spec.add_development_dependency 'rubocop', '~> 1.36.0'
	spec.add_development_dependency 'rubocop-performance', '~> 1.0'
	spec.add_development_dependency 'rubocop-rspec', '~> 2.0'
end
