# frozen_string_literal: true

require_relative 'form/fields'
require_relative 'form/outcome'

module Formalism
	## Class for forms
	class Form < Action
		include Form::Fields

		def self.inherited(child)
			child.fields_and_nested_forms.merge!(fields_and_nested_forms)
		end

		def initialize(params = {})
			super

			fill_fields_and_nested_forms
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

			Outcome.new(errors, super)
		end

		protected

		def errors
			@errors ||= Set.new
		end

		private

		def validate; end

		def fill_fields_and_nested_forms
			self.class.fields_and_nested_forms.each do |name, options|
				if options.key?(:form)
					fill_nested_form name, options
				else
					fill_field name, options
				end
			end
		end

		def fill_field(name, options)
			key = options.fetch(:key, name)

			if !@params.key?(key) && (!options.key?(:default) || fields.include?(key))
				return
			end

			default = options[:default]
			send "#{name}=",
				if @params.key?(key) then @params[key]
				else default.is_a?(Proc) ? instance_exec(&default) : default
				end
		end

		def fill_nested_form(name, options)
			return unless (form = initialize_nested_form(name, options))

			nested_forms[name] = form

			return if @params.key?(name) || !options.key?(:default)

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
