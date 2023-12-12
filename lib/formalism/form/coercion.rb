# frozen_string_literal: true

require 'gorilla_patch/inflections'

Dir[
	File.join(__dir__, 'coercion', '**', '*.rb')
]
	.sort_by! { |file| [File.basename(file).start_with?('_') ? 1 : 2, file] }
	.each { |file| require file }

## https://github.com/bbatsov/rubocop/issues/5831
module Formalism
	class Form < Action
		## Class for coercion (check, initialization)
		class Coercion
			def initialize(type, of = nil)
				@type = type
				@of = of
			end

			def check
				## It's custom error! But cop triggers for single argument anyway.
				# rubocop:disable Style/RaiseArgs
				raise NoCoercionError.new(@type) unless exist?
				# rubocop:enable Style/RaiseArgs

				return unless const_name == 'Array' && @of

				self.class.new(@of).check
			end

			def result_for(value)
				coercion_class = exist? ? const_name : 'Base'

				self.class.const_get(coercion_class, false).new(value, @of).result
			end

			private

			using GorillaPatch::Inflections

			def const_name
				@type.to_s.camelize
			end

			def exist?
				self.class.const_defined?(const_name, false)
			rescue NameError
				false
			end
		end

		## Error for undefined type in coercion
		class NoCoercionError < ArgumentError
			def initialize(type)
				super("Formalism has no coercion to #{type}")
			end
		end
	end
end
