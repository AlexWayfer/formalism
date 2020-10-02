# frozen_string_literal: true

require_relative 'float'

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to BigDecimal
			class BigDecimal < Float
				private

				def send_conversion_method
					BigDecimal(@value.to_s)
				end
			end
		end
	end
end
