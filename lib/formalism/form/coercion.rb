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

		def self.check(type, options = {})
			## It's custom error! But cop triggers for single argument anyway.
			# rubocop:disable Style/RaiseArgs
			raise NoCoercionError.new(type) unless defined_for?(type)
			# rubocop:enable Style/RaiseArgs

			return unless convert_type(type) == Array && options[:of]

			check options[:of]
		end

		def self.convert_type(type)
			return type if type.nil? || type.is_a?(Class)

			const_name = type.capitalize
			return type unless Object.const_defined?(const_name)

			Object.const_get(const_name)
		end

		def initialize(value, type:, of: nil)
			@value = value
			@type = self.class.convert_type type
			@of = self.class.convert_type of
		end

		def result
			return @value unless should_be_coreced?

			result = send self.class.method_for @type

			if result.is_a?(Array) && @of
				result.map! do |element|
					self.class.new(element, type: @of).result
				end
			end

			result
		end

		private

		def should_be_coreced?
			@type && (
				!@type.is_a?(Class) || @type == Array || !@value.is_a?(@type)
			)
		end

		def to_string
			@value&.to_s
		end

		def to_integer
			## https://stackoverflow.com/a/1235990/2630849
			@value.to_i if /\A[-+]?\d+\z/.match? @value.to_s
		end

		def to_float
			## https://stackoverflow.com/a/36946626/2630849
			@value.to_f if /\A[-+]?(?:\d+(?:\.\d*)?|\.\d+)\z/.match? @value.to_s
		end

		def to_time
			return if @value.nil?

			Time.parse(@value)
		end

		def to_boolean
			@value && @value.to_s != 'false' ? true : false
		end

		def to_symbol
			@value&.to_sym
		end

		def to_array
			@value&.to_a
		end

		def to_date
			return if @value.nil?

			Date.parse(@value)
		end
	end

	private_constant :Coercion

	## Error for undefined type in coercion
	class NoCoercionError < ArgumentError
		def initialize(type)
			super "Formalism has no coercion to #{type}"
		end
	end
end
