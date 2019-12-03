# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Array
			class Array < Base
				def initialize(value, of = nil)
					super

					@of = of
				end

				private

				def should_be_coreced?
					true
				end

				def execute
					result = @value&.to_a

					return result unless @of

					result.map! { |element| Coercion.new(@of).result_for(element) }
				end
			end
		end
	end
end
