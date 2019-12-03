# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Hash
			class Hash < Base
				private

				def execute
					@value&.to_h
				end
			end
		end
	end
end
