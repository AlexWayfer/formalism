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

					instance_variable = options[:instance_variable] ||= name
					fields_and_nested_forms[name] = options.merge(form: form)

					define_method("#{name}_form") { nested_forms[name] }

					define_method(name) do
						nested_forms[name].public_send(instance_variable)
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
				merging_fields, merging_nested_forms =
					[fields, nested_forms].map do |hash|
						hash.select do |name, _value|
							self.class.fields_and_nested_forms[name].fetch(:merge, true)
						end
					end

				merging_fields.merge(
					merging_nested_forms
						.map { |name, _nested_form| [name, public_send(name)] }.to_h
				)
			end
		end
	end
end
