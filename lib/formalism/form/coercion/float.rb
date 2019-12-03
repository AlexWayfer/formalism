# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Float
			class Float < Numeric
				## https://stackoverflow.com/a/36946626/2630849
				VALUE_REGEXP = wrap_value_regexp '[-+]?(?:\d+(?:\.\d*)?|\.\d+)'

				CONVERSION_METHOD = :to_f
			end
		end
	end
end
