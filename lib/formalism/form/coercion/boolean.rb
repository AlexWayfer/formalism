# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to boolean
			class Boolean < Base
				private

				## It's standard method, but for Boolean
				# rubocop:disable Naming/PredicateMethod
				def execute
					!@value.nil? && @value.to_s != 'false'
				end
				# rubocop:enable Naming/PredicateMethod
			end
		end
	end
end
