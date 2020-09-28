# frozen_string_literal: true

module Formalism
	class Form < Action
		class Coercion
			## Base class for coercion to Numeric
			class Numeric < Base
				class << self
					private

					def wrap_value_regexp(content)
						/\A\s*#{content}\s*\z/.freeze
					end
				end

				private

				def execute
					return unless self.class::VALUE_REGEXP.match? @value.to_s

					send_conversion_method
				end

				def send_conversion_method
					@value.public_send(self.class::CONVERSION_METHOD)
				end
			end
		end
	end
end
