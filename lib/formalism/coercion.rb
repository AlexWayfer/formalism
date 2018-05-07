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
			@type = convert_type type
		end

		def result
			return @value if @type.nil? || (@type.is_a?(Class) && @value.is_a?(@type))
			send self.class.method_for @type
		end

		private

		def convert_type(type)
			return type if type.nil? || type.is_a?(Class)
			const_name = type.capitalize
			return type unless Object.const_defined?(const_name)
			Object.const_get(const_name)
		end

		def to_string
			@value.to_s
		end

		def to_integer
			int_value = @value.to_i
			return if @value != int_value.to_s
			int_value
		end

		def to_time
			return if @value.nil?
			Time.parse(@value)
		end

		def to_boolean
			@value ? true : false
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
