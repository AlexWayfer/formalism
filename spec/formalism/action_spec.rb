# frozen_string_literal: true

describe Formalism::Action do
	let(:test_action_class) do
		Class.new(described_class) do
			private

			def execute
				params[:string].upcase
			end
		end
	end

	subject(:test_action) { test_action_class.new(params) }

	describe '#params' do
		subject { test_action.params }

		let(:params) { { string: 'foo' } }

		it { is_expected.to eq params }
		it { is_expected.not_to be params }

		context 'params does not received' do
			let(:params) { nil }

			it { is_expected.to eq({}) }
		end
	end

	shared_examples 'run' do
		context 'with correct value' do
			let(:params) { { string: +'foo' } }

			it { is_expected.to eq 'FOO' }
		end

		context 'with incorrect value' do
			let(:params) { { string: 42 } }

			it do
				expect { subject }.to raise_error(
					NoMethodError, "undefined method `upcase' for 42:Integer"
				)
			end
		end
	end

	describe '#run' do
		subject { test_action.run }

		include_examples 'run'
	end

	describe '.run' do
		subject { test_action_class.run(params) }

		include_examples 'run'
	end
end
