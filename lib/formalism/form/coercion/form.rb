# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Formalism::Form
			class Form < Base
				def initialize(value, form_class:, **)
					super value

					@form_class = form_class
				end

				private

				def execute
					@form_class.new(@value)
				end
			end
		end
	end
end
