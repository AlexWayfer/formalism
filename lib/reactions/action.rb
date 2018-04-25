# frozen_string_literal: true

module Reactions
	## Class for any action
	class Action
		def run
			execute
		end

		## Class for action with validation
		class WithValidation < self
			def run
				errors.clear
				validate
				return false if errors.any?
				super
				true
			end

			def errors
				@errors ||= Set.new
			end
		end
	end
end
