# frozen_string_literal: true

describe Formalism::Action do
	subject(:test_action) do
		Class.new(described_class) do
			def initialize(string)
				@string = string
			end

			private

			def execute
				@string.upcase
			end
		end
	end

	describe '#run' do
		subject { test_action.new(string).run }

		context 'with correct value' do
			let(:string) { +'foo' }

			it { is_expected.to eq 'FOO' }
		end

		context 'with incorrect value' do
			let(:string) { 42 }

			it do
				expect { subject }.to raise_error(
					NoMethodError, "undefined method `upcase' for 42:Integer"
				)
			end
		end
	end
end
