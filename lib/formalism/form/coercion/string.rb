# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to String
			class String < Base
				private

				def execute
					@value&.to_s
				end
			end
		end
	end
end
