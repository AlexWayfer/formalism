# frozen_string_literal: true

require 'gorilla_patch/deep_dup'
require_relative 'coercion'

module Formalism
	## Class for forms
	class Form < Action
		class << self
			def fields
				@fields ||= {}
			end

			def nested_forms
				@nested_forms ||= {}
			end

			def field(name, type = nil, **options)
				Coercion.check type unless type.nil?

				fields[name] = options.merge(type: type)

				attr_reader name

				private(
					define_method("#{name}=") do |value|
						value = Coercion.new(value, type).result
						instance_variable_set "@#{name}", value
						fields[name] = value
					end
				)
			end

			def nested(name, form = nil, **options)
				unless form || options.key?(:initialize)
					raise(
						ArgumentError,
						'Neither form class nor initialize block is not present'
					)
				end

				nested_forms[name] = options.merge(form: form)

				define_method("#{name}_form") { nested_forms[name] }
				define_method(name) { nested_forms[name].public_send(name) }
			end

			def inherited(child)
				child.fields.merge!(fields)
			end

			def run(*args)
				new(*args).run
			end
		end

		attr_reader :params

		using GorillaPatch::DeepDup

		def initialize(params = {})
			@params = params.deep_dup || {}

			fill_fields

			fill_nested_forms
		end

		def fields
			@fields ||= {}
		end

		def valid?
			errors.clear
			nested_forms.each_value(&:valid?)
			validate
			errors.merge(nested_forms.each_value.map(&:errors)).flatten!
			return false if errors.any?
			true
		end

		def run
			return Outcome.new(errors) unless valid?
			nested_forms.each_value(&:run)
			Outcome.new(errors, super)
		end

		private

		def errors
			@errors ||= Set.new
		end

		def validate; end

		def nested_forms
			@nested_forms ||= {}
		end

		def fill_fields
			self.class.fields.each do |name, options|
				key = options.fetch(:key, name)
				next unless @params.key?(key) || options.key?(:default)
				default = options[:default]
				send "#{name}=", @params.fetch(
					key, default.is_a?(Proc) ? instance_exec(&default) : default
				)
			end
		end

		def fill_nested_forms
			self.class.nested_forms.each do |name, options|
				form = initialize_nested_form(name, options)
				next unless form
				nested_forms[name] = form
				next if @params.key?(name) || options.key?(:initialize)
				default = options[:default]
				form.instance_variable_set(
					"@#{name}", default.is_a?(Proc) ? instance_exec(&default) : default
				)
			end
		end

		def initialize_nested_form(name, options)
			instance_exec(
				options[:form],
				&options.fetch(:initialize, ->(form) { form.new(params[name]) })
			)
		end

		## Private class for results
		class Outcome
			attr_reader :errors, :result

			def initialize(errors, result = nil)
				@errors = errors
				@result = result
			end

			def success?
				@errors.empty?
			end
		end

		private_constant :Outcome
	end
end
