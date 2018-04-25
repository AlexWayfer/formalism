# frozen_string_literal: true

describe Reactions::Action do
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

	describe described_class::WithValidation do
		subject(:test_action_with_validation) do
			Class.new(test_action) do
				private

				def validate
					return if @string.is_a?(String)
					errors.add('class is not String')
				end

				def execute
					@string.upcase!
				end
			end
		end

		describe '#run' do
			subject { test_action_with_validation.new(string).run }

			context 'with correct value' do
				let(:string) { +'foo' }

				it { is_expected.to be true }
			end

			context 'with incorrect value' do
				let(:string) { 42 }

				it { is_expected.to be false }
			end
		end

		describe '#errors' do
			let(:test_action_object) { test_action_with_validation.new(string) }
			before { test_action_object.run }
			subject { test_action_object.errors }

			context 'with correct value' do
				let(:string) { +'foo' }

				it { is_expected.to be_empty }
			end

			context 'with incorrect value' do
				let(:string) { 42 }

				it { is_expected.to eq(['class is not String'].to_set) }
			end
		end
	end
end
