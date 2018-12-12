# frozen_string_literal: true

describe Formalism::Form::ValidationError do
	subject { described_class.new(errors) }

	let(:errors) { ['Foo is incorrect', 'Bar is too low'] }

	describe '#errors' do
		subject { super().errors }

		it { is_expected.to eq errors }
	end

	describe '#inspect' do
		subject { super().message }

		it { is_expected.to eq "Outcome has errors: #{errors}" }
	end
end
