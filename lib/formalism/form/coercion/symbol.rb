# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Symbol
			class Symbol < Base
				private

				def execute
					@value&.to_sym
				end
			end
		end
	end
end
