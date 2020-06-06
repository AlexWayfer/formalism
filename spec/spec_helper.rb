# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
	add_filter '/spec/'
end
SimpleCov.start

require 'pry-byebug'

require_relative '../lib/formalism'
