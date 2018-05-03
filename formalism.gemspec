# frozen_string_literal: true

require 'date'

Gem::Specification.new do |s|
	s.name          = 'formalism'
	s.version       = '0.0.0'
	s.date          = Date.today.to_s
	s.summary       = 'Forms with input data validations and nesting'
	s.description   = <<~DESC
		Simple actions and complex forms with validations, nesting, etc.
	DESC
	s.authors       = ['Alexander Popov']
	s.email         = 'alex.wayfer@gmail.com'
	s.files         = `git ls-files`.split($RS)
	s.homepage      = 'https://github.com/AlexWayfer/formalism'
	s.license       = 'MIT'

	s.required_ruby_version = '>= 2.3.0'

	s.add_dependency 'gorilla-patch', '~> 2.9'

	s.add_development_dependency 'codecov', '~> 0'
	s.add_development_dependency 'rake', '~> 12'
	s.add_development_dependency 'rspec', '~> 3'
	s.add_development_dependency 'rubocop', '~> 0.54'
	s.add_development_dependency 'simplecov', '~> 0'
end
