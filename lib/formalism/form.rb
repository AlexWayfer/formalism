# frozen_string_literal: true

require_relative 'coercion'
require_relative 'form/outcome'

module Formalism
	## Class for forms
	class Form < Action
		class << self
			def fields_and_nested_forms
				@fields_and_nested_forms ||= {}
			end

			def field(name, type = nil, **options)
				Coercion.check type unless type.nil?

				fields_and_nested_forms[name] = options.merge(type: type)

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
					raise ArgumentError, 'Neither form class nor initialize block ' \
						'is not present'
				end

				instance_variable = options[:instance_variable] ||= name
				fields_and_nested_forms[name] = options.merge(form: form)

				define_method("#{name}_form") { nested_forms[name] }

				define_method(name) do
					nested_forms[name].public_send(instance_variable)
				end
			end

			def inherited(child)
				child.fields_and_nested_forms.merge!(fields_and_nested_forms)
			end
		end

		def initialize(params = {})
			super

			fill_fields_and_nested_forms
		end

		def fields
			@fields ||= {}
		end

		def valid?
			errors.clear
			nested_forms.each_value(&:valid?)
			validate
			merge_errors_of_nested_forms
			return false if errors.any?
			true
		end

		def run
			return Outcome.new(errors) unless valid?
			nested_forms.each_value(&:run)
			Outcome.new(errors, super)
		end

		protected

		def errors
			@errors ||= Set.new
		end

		private

		def validate; end

		def nested_forms
			@nested_forms ||= {}
		end

		def fill_fields_and_nested_forms
			self.class.fields_and_nested_forms.each do |name, options|
				next fill_nested_form name, options if options.key?(:form)
				key = options.fetch(:key, name)
				next unless @params.key?(key) || options.key?(:default)
				default = options[:default]
				send "#{name}=", @params.fetch(
					key, default.is_a?(Proc) ? instance_exec(&default) : default
				)
			end
		end

		def fill_nested_form(name, options)
			return unless (form = initialize_nested_form(name, options))
			nested_forms[name] = form
			return if @params.key?(name) || options.key?(:initialize)
			default = options[:default]
			form.instance_variable_set(
				"@#{options[:instance_variable]}",
				default.is_a?(Proc) ? instance_exec(&default) : default
			)
		end

		def initialize_nested_form(name, options)
			instance_exec(
				options[:form],
				&options.fetch(:initialize, ->(form) { form.new(params[name]) })
			)
		end

		def merge_errors_of_nested_forms
			nested_forms.each_value { |nested_form| errors.merge(nested_form.errors) }
		end
	end
end
