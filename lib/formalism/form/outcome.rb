# frozen_string_literal: true

module Formalism
	## https://github.com/rubocop-hq/rubocop/issues/5831
	class Form < Action
		## Private class for results
		class Outcome
			attr_reader :errors

			def initialize(errors, result = nil)
				@errors = errors
				@result = result
			end

			def success?
				@errors.empty?
			end

			def result
				raise ValidationError, errors if errors.any?

				@result
			end
		end
	end
end
