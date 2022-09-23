# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Class for coercion to Object (formally everything is Object)
			class Object < Base
				private

				def execute
					## There are other `is_a?` checks, fuck it
					# return unless @value.respond_to? :is_a? ## BasicObject

					@value if @value.is_a? ::Object
				end
			end
		end
	end
end
