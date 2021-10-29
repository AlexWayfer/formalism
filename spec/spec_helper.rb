# frozen_string_literal: true

require 'simplecov'

if ENV['CI']
	require 'simplecov-cobertura'
	SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start

require 'pry-byebug'

require_relative '../lib/formalism'
