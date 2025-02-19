# frozen_string_literal: true

describe Formalism::Action do
	subject(:test_action) { test_action_class.new(params) }

	let(:test_action_class) do
		Class.new(described_class) do
			private

			def execute
				params[:string].upcase
			end
		end
	end

	let(:correct_run_params) do
		{ string: +'foo' }
	end

	let(:incorrect_run_params) do
		{ string: 42 }
	end

	describe '#params' do
		subject { test_action.params }

		let(:params) { { string: 'foo' } }

		it { is_expected.to eq params }
		it { is_expected.not_to be params }

		context 'without received params' do
			let(:params) { nil }

			it { is_expected.to eq({}) }
		end
	end

	shared_examples 'run' do
		context 'with correct value' do
			let(:params) { correct_run_params }

			it { is_expected.to eq 'FOO' }
		end

		context 'with incorrect value' do
			let(:params) { incorrect_run_params }

			it do
				expect { subject }.to raise_error(
					NoMethodError, /undefined method [`']upcase[`'] for .+Integer/
				)
			end
		end
	end

	describe '#run' do
		subject { test_action.run }

		include_examples 'run'

		context 'when `runnable` if false' do
			before do
				test_action.runnable = false
			end

			context 'with correct params' do
				let(:params) { correct_run_params }

				it { is_expected.to be_nil }
			end

			context 'with incorrect params' do
				let(:params) { incorrect_run_params }

				it { is_expected.to be_nil }
			end
		end
	end

	describe '.run' do
		subject { test_action_class.run(params) }

		include_examples 'run'
	end
end
