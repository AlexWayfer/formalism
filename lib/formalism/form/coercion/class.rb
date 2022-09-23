# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Class
			class Class < Base
				private

				def execute
					return @value if @value.is_a? Class

					return if @value.to_s.empty?

					::Object.const_get(@value)
				end
			end
		end
	end
end
