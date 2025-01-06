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

	spec.required_ruby_version = '>= 3.0', '< 3.5'

	spec.add_dependency 'gorilla_patch', '>= 4', '< 6'
	spec.add_dependency 'module_methods', '~> 0.1.0'
end
