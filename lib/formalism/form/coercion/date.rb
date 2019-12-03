# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Date
			class Date < Base
				private

				def execute
					return if @value.nil?

					::Date.parse(@value)
				rescue ArgumentError => e
					raise unless e.message == 'invalid date'
				end
			end
		end
	end
end
