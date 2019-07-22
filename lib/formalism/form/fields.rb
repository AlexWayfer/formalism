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
					Coercion.check type, options unless type.nil?

					fields_and_nested_forms[name] = options.merge(type: type)

					define_field_methods(name)
				end

				def nested(name, form = nil, **options)
					unless form || options.key?(:initialize)
						raise ArgumentError, 'Neither form class nor initialize block ' \
							'is not present'
					end

					fields_and_nested_forms[name] = options.merge(form: form)

					define_nested_form_methods(name)
				end

				private

				def define_field_methods(name)
					module_for_accessors.instance_exec do
						define_method(name) { fields[name] }

						private

						define_method("#{name}=") do |value|
							options = self.class.fields_and_nested_forms[name]
							value = Coercion.new(value, **options.slice(:type, :of)).result
							fields[name] = value
						end
					end
				end

				def define_nested_form_methods(name)
					module_for_accessors.instance_exec do
						define_method("#{name}_form") { nested_forms[name] }

						define_method(name) { nested_forms[name].instance }

						private

						define_method("params_for_nested_#{name}") { @params[name] }
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
					merge = self.class.fields_and_nested_forms[name].fetch(:merge, true)
					merge.is_a?(Proc) ? instance_exec(value, &merge) : merge
				end
			end
		end
	end
end
