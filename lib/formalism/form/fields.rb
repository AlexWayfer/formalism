# frozen_string_literal: true

require_relative 'coercion'

module Formalism
	class Form < Action
		## Extend some module or clas with this module for fields
		module Fields
			## Module for class methods
			module ClassMethods
				def included(something)
					something.extend ClassMethods

					something.fields_and_nested_forms.merge!(fields_and_nested_forms)
				end

				def fields_and_nested_forms
					@fields_and_nested_forms ||= {}
				end

				def field(name, type = nil, **options)
					Coercion.check type unless type.nil?

					fields_and_nested_forms[name] = options.merge(type: type)

					define_method(name) { fields[name] }

					private(
						define_method("#{name}=") do |value|
							value = Coercion.new(value, type).result
							fields[name] = value
						end
					)
				end

				def nested(name, form = nil, **options)
					unless form || options.key?(:initialize)
						raise ArgumentError, 'Neither form class nor initialize block ' \
							'is not present'
					end

					options[:instance_variable] ||= name
					options[:instance_variable_name] = "@#{options[:instance_variable]}"
					fields_and_nested_forms[name] = options.merge(form: form)

					define_nested_form_methods(name)
				end

				private

				def define_nested_form_methods(name)
					define_method("#{name}_form") { nested_forms[name] }

					define_method(name) do
						nested_forms[name].public_send(
							self.class.fields_and_nested_forms[name][:instance_variable]
						)
					end
				end
			end

			private_constant :ClassMethods

			extend ClassMethods

			def fields
				@fields ||= {}
			end

			private

			def nested_forms
				@nested_forms ||= {}
			end

			def fields_and_nested_forms
				merging_fields = select_for_merging :fields
				merging_nested_forms = select_for_merging :nested_forms

				merging_fields.merge(
					merging_nested_forms
						.map { |name, _nested_form| [name, public_send(name)] }
						.to_h
				)
			end

			def select_for_merging(type)
				send(type).select do |name, value|
					merge_option =
						self.class.fields_and_nested_forms[name].fetch(:merge, true)

					next merge_option unless type == :nested_form

					merge_option && value.instance_variable_defined?(
						self.class.fields_and_nested_forms[name][:instance_variable_name]
					)
				end
			end
		end
	end
end
