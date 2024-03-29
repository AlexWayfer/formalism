# frozen_string_literal: true

module Formalism
	class Form < Action
		## Module for filling forms with data
		module Filling
			private

			def fill_fields_and_nested_forms
				@filled_fields_and_nested_forms = []

				self.class.fields_and_nested_forms.each_key do |name|
					fill_field_or_nested_form name
				end
			end

			def fill_field_or_nested_form(name)
				return if @filled_fields_and_nested_forms.include? name

				options = self.class.fields_and_nested_forms[name]

				fill_depends(*options[:depends_on])

				if options.key?(:form)
					fill_nested_form name, options
				else
					fill_field name, options
				end

				@filled_fields_and_nested_forms.push name
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
				args = args_for_nested_form(name, options)

				return unless (form = initialize_nested_form(options, args))

				nested_forms[name] = form
			end

			def process_default(default)
				default.is_a?(Proc) ? instance_exec(&default) : default
			end

			def initialize_nested_form(options, args)
				result =
					instance_exec options[:form], &options.fetch(:initialize, ->(form) { form.new(*args) })
				result.runnable = false unless runnable
				result
			end

			def args_for_nested_form(name, options)
				if @params.key?(name)
					[send(:"params_for_nested_#{name}")]
				elsif instance_respond_to?(name)
					[instance_public_send(name)]
				elsif options.key?(:default)
					[process_default(options[:default])]
				else
					[]
				end
			end
		end

		private_constant :Filling
	end
end
