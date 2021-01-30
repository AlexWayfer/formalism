# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to boolean
			class Boolean < Base
				private

				def execute
					!@value.nil? && @value.to_s != 'false'
				end
			end
		end
	end
end
