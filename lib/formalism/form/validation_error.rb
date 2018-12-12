# frozen_string_literal: true

module Formalism
	class Form < Action
		## When trying to get `#result` from unsuccessful outcome
		class ValidationError < StandardError
			attr_reader :errors

			def initialize(errors)
				@errors = errors
				super "Outcome has errors: #{errors.to_a}"
			end
		end
	end
end
