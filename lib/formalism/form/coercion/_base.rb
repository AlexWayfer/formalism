# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Base class for coercion
			class Base
				def initialize(value, *)
					@value = value

					type_name = self.class.name.split('::')[3..-1].join('::')

					@type =
						if Object.const_defined?(type_name, false)
						then Object.const_get(type_name, false)
						else type_name
						end
				end

				def result
					return @value unless should_be_coreced?

					execute
				end

				private

				def should_be_coreced?
					@type != 'Base' && !(@type.is_a?(Class) && @value.is_a?(@type))
				end
			end
		end
	end
end
