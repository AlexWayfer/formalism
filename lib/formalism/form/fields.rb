# frozen_string_literal: true

require 'module_methods'

require_relative 'coercion'

module Formalism
	class Form < Action
		## Extend some module or class with this module for fields
		module Fields
			extend ::ModuleMethods::Extension

			## Module for class methods
			module ClassMethods
				def included(something)
					super

					fields_and_nested_forms.each do |name, options|
						if options.key?(:form)
							something.nested name, options[:form], **options
						else
							something.field name, options[:type], **options
						end
					end
				end

				def fields_and_nested_forms
					@fields_and_nested_forms ||= {}
				end

				def field(name, type = nil, **options)
					Coercion.new(type, options[:of]).check unless type.nil?

					fields_and_nested_forms[name] = options.merge(type: type)

					define_field_methods(name)
				end

				def nested(name, form = nil, **options)
					unless form || options.key?(:initialize)
						raise ArgumentError, 'Neither form class nor initialize block is not present'
					end

					fields_and_nested_forms[name] = options.merge(form: form)

					define_nested_form_methods(name)
				end

				private

				def remove_field(name)
					fields_and_nested_forms.delete name

					undef_method name
					undef_method "#{name}="
				end

				def define_field_methods(name)
					module_for_accessors.instance_exec do
						define_method(name) { fields[name] }

						private

						define_method("#{name}=") do |value|
							options = self.class.fields_and_nested_forms[name]
							coerced_value =
								Coercion.new(*options.values_at(:type, :of)).result_for(value)
							fields[name] = coerced_value
						end
					end
				end

				def define_nested_form_methods(name)
					module_for_accessors.instance_exec do
						define_method("#{name}_form") { nested_forms[name] }

						define_method(name) { nested_forms[name].instance }
					end

					define_params_for_nested_method name
				end

				def define_params_for_nested_method(name)
					params_method_name = "params_for_nested_#{name}"
					params_method_defined =
						method_defined?(params_method_name) ||
						private_method_defined?(params_method_name)

					module_for_accessors.instance_exec do
						private

						define_method(params_method_name) { @params[name] } unless params_method_defined
					end
				end

				def module_for_accessors
					if const_defined?(:FieldsAccessors, false)
						mod = const_get(:FieldsAccessors)
					else
						mod = const_set(:FieldsAccessors, Module.new)
						include mod
					end
					mod
				end
			end

			def fields(for_merge: false)
				@fields ||= {}

				return @fields unless for_merge

				select_for_merge(:fields)
			end

			def to_params
				fields.merge(
					nested_forms.each_with_object({}) do |(name, nested_form), result|
						result.merge! nested_form_to_params name, nested_form
					end
				)
			end

			private

			def nested_forms
				@nested_forms ||= {}
			end

			def fields_and_nested_forms(for_merge: true)
				merging_nested_forms =
					for_merge ? select_for_merge(:nested_forms) : nested_forms

				fields(for_merge: for_merge).merge(
					merging_nested_forms
						.map { |name, _nested_form| [name, public_send(name)] }
						.to_h
				)
			end

			def select_for_merge(type)
				send(type).select do |name, value|
					merge = self.class.fields_and_nested_forms[name].fetch(:merge, true)
					merge.is_a?(Proc) ? instance_exec(value, &merge) : merge
				end
			end

			def nested_form_to_params(name_of_nested_form, nested_form)
				{ name_of_nested_form => nested_form.to_params }
			end
		end
	end
end
