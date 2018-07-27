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

		using GorillaPatch::DeepDup

		def initialize(params = {})
			@params = params.deep_dup || {}
		end

		def run
			execute
		end
	end
end
