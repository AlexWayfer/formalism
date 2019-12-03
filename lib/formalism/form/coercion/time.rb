# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Time
			class Time < Base
				private

				def execute
					case @value
					when ::String
						::Time.parse @value
					when ::Integer
						::Time.at @value
					end
				rescue ArgumentError => e
					raise unless e.message.include? 'out of range'
				end
			end
		end
	end
end
