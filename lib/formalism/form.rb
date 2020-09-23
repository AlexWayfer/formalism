# frozen_string_literal: true

require_relative 'form/fields'
require_relative 'form/filling'
require_relative 'form/outcome'
require_relative 'form/validation_error'

module Formalism
	## Class for forms
	class Form < Action
		include Form::Fields
		include Filling

		attr_reader :instance

		def self.inherited(child)
			super

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
			return unless runnable

			errors.clear

			nested_forms.each_value(&:valid?)

			validate

			merge_errors_of_nested_forms

			return false if errors.any?

			true
		end

		def run
			return unless runnable

			return Outcome.new(errors) unless valid?

			Outcome.new(errors, super)
		end

		protected

		def errors
			@errors ||= Set.new
		end

		private

		def validate; end

		def instance_respond_to?(name)
			return false unless defined? @instance

			@instance.respond_to?(name)
		end

		def instance_public_send(name)
			return false unless defined? @instance

			@instance.public_send(name)
		end

		def merge_errors_of_nested_forms
			nested_forms.each do |name, nested_form|
				should_be_merged = self.class.fields_and_nested_forms[name].fetch(:merge_errors, true)
				should_be_merged = instance_exec(&should_be_merged) if should_be_merged.is_a?(Proc)

				next unless should_be_merged && nested_form.errors.any?

				merge_errors_of_nested_form name, nested_form
			end
		end

		def merge_errors_of_nested_form(_name, nested_form)
			errors.merge nested_form.errors
		end
	end
end
