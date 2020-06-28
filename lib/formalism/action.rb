# frozen_string_literal: true

require 'gorilla_patch/deep_dup'

module Formalism
	## Class for any action
	class Action
		class << self
			def run(*args)
				new(*args).run
			end
		end

		attr_reader :params
		attr_accessor :runnable

		using GorillaPatch::DeepDup

		def initialize(params = {})
			@runnable = true unless defined? @runnable
			@params = params.deep_dup || {}
		end

		def run
			return unless runnable

			execute
		end
	end
end
