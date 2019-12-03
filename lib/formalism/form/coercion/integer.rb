# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Integer
			class Integer < Numeric
				## https://stackoverflow.com/a/1235990/2630849
				VALUE_REGEXP = wrap_value_regexp '[-+]?\d+'

				CONVERSION_METHOD = :to_i
			end
		end
	end
end
