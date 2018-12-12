# frozen_string_literal: true

require_relative 'form/fields'
require_relative 'form/outcome'
require_relative 'form/validation_error'

module Formalism
	## Class for forms
	class Form < Action
		include Form::Fields

		attr_reader :instance

		def self.inherited(child)
			child.fields_and_nested_forms.merge!(fields_and_nested_forms)
		end

		def initialize(params_or_instance = {})
			if params_or_instance.is_a?(Hash)
				super
			else
				super({})

				@instance = params_or_instance
			end

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

		def filled_fields_and_nested_forms
			@filled_fields_and_nested_forms ||= []
		end

		def fill_fields_and_nested_forms
			self.class.fields_and_nested_forms.each_key do |name|
				fill_field_or_nested_form name
			end
		end

		def fill_field_or_nested_form(name)
			return if filled_fields_and_nested_forms.include? name

			options = self.class.fields_and_nested_forms[name]

			fill_depends(*options[:depends_on])

			if options.key?(:form)
				fill_nested_form name, options
			else
				fill_field name, options
			end

			filled_fields_and_nested_forms.push name
		end

		def fill_depends(*depends_on)
			depends_on.each do |depends_name|
				next unless self.class.fields_and_nested_forms.key?(depends_name)

				fill_field_or_nested_form depends_name
			end
		end

		def fill_field(name, options)
			key = options.fetch(:key, name)
			setter = "#{name}="

			if @params.key?(key)
				send setter, @params[key]
			elsif instance_respond_to?(key)
				send setter, instance_public_send(key)
			elsif options.key?(:default) && !fields.include?(key)
				send setter, process_default(options[:default])
			end
		end

		def fill_nested_form(name, options)
			return unless (form = initialize_nested_form(name, options))

			nested_forms[name] = form
		end

		def process_default(default)
			default.is_a?(Proc) ? instance_exec(&default) : default
		end

		def initialize_nested_form(name, options)
			args =
				if @params.key?(name) then [send("params_for_nested_#{name}")]
				elsif instance_respond_to?(name) then [instance_public_send(name)]
				elsif options.key?(:default) then [process_default(options[:default])]
				else []
				end

			instance_exec(
				options[:form],
				&options.fetch(:initialize, ->(form) { form.new(*args) })
			)
		end

		def instance_respond_to?(name)
			@instance.respond_to?(name)
		end

		def instance_public_send(name)
			@instance.public_send(name)
		end

		def merge_errors_of_nested_forms
			nested_forms.each_value { |nested_form| errors.merge(nested_form.errors) }
		end
	end
end
