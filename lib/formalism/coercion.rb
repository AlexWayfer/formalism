# frozen_string_literal: true

## https://github.com/bbatsov/rubocop/issues/5831
module Formalism
	## Internal class for coercions
	class Coercion
		def self.method_for(type)
			"to_#{type.to_s.downcase}"
		end

		def self.defined_for?(type)
			private_method_defined? method_for type
		end

		def self.check(type)
			## It's custom error!
			# rubocop:disable Style/RaiseArgs
			raise NoCoercionError.new(type) unless defined_for?(type)
			# rubocop:enable Style/RaiseArgs
		end

		def initialize(value, type)
			@value = value
			@type = type
		end

		def result
			return @value if @type.nil? || @value.is_a?(@type)
			send self.class.method_for @type
		end

		private

		def to_string
			@value.to_s
		end

		def to_integer
			int_value = @value.to_i
			return if @value != int_value.to_s
			int_value
		end

		def to_time
			Time.parse(@value)
		end
	end

	private_constant :Coercion

	## Error for undefined type in coercion
	class NoCoercionError < ArgumentError
		def initialize(type)
			@type = type
		end

		def message
			"Formalism has no coercion to #{@type}"
		end
	end
end
