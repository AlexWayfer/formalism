# frozen_string_literal: true

## This is unit test, created to simplify testing of different coercions
## You can find integration test in spec/formalism/form/fields_spec.rb
## (Formalism::Form -> .field -> coersion)
##
## In tests `eql` used instead of `eq` to determine result type
describe 'Formalism::Coercion' do
	let(:value) {}
	let(:field_type) { [type] }

	let(:form) do
		## Pass method call result throug instance_eval inside Class.new
		field_type = self.field_type

		Class.new(Formalism::Form) do
			field :value, *field_type
		end
	end

	subject(:coercion_result) { form.new(value: value).value }

	shared_examples 'it parses nil' do |expected_result = nil|
		let(:value) { nil }

		it { is_expected.to eql(expected_result) }
	end

	shared_examples 'it parses empty string' do |expected_result = nil|
		let(:value) { '' }

		it { is_expected.to eql(expected_result) }
	end

	shared_examples 'it parses empty array' do |expected_result = nil|
		let(:value) { [] }

		it { is_expected.to eql(expected_result) }
	end

	shared_examples 'it parses empty hash' do |expected_result = nil|
		let(:value) { {} }

		it { is_expected.to eql(expected_result) }
	end

	describe '#to_string' do
		let(:type) { String }

		it_behaves_like 'it parses nil'
		it_behaves_like 'it parses empty string', ''
		it_behaves_like 'it parses empty array', '[]'
		it_behaves_like 'it parses empty hash', '{}'
	end

	describe '#to_integer' do
		let(:type) { Integer }

		it_behaves_like 'it parses nil'
		it_behaves_like 'it parses empty string'
		it_behaves_like 'it parses empty array'
		it_behaves_like 'it parses empty hash'

		context 'string with integer number' do
			let(:value) { '42' }

			it { is_expected.to eql 42 }
		end

		context 'string with float number' do
			let(:value) { '42.5' }

			it { is_expected.to be_nil }
		end

		context 'string with malformed number' do
			let(:value) { '42 km' }

			it { is_expected.to be_nil }
		end
	end

	describe '#to_float' do
		let(:type) { Float }

		it_behaves_like 'it parses nil'
		it_behaves_like 'it parses empty string'
		it_behaves_like 'it parses empty array'
		it_behaves_like 'it parses empty hash'

		context 'string with integer number' do
			let(:value) { '42' }

			it { is_expected.to eql 42.0 }
		end

		context 'string with float number' do
			let(:value) { '42.5' }

			it { is_expected.to eql 42.5 }
		end

		context 'string with malformed number' do
			let(:value) { '42 km' }

			it { is_expected.to be_nil }
		end
	end

	describe '#to_time' do
		let(:type) { Time }

		it_behaves_like 'it parses nil'

		context 'string with some time' do
			let(:value) { '1.1.2001 11:00' }

			it { is_expected.to eql Time.new(2001, 1, 1, 11, 0) }
		end

		context 'string with malformed time' do
			context 'hours' do
				let(:value) { '25:00' }

				it { is_expected.to be_nil }
			end

			context 'minutes' do
				let(:value) { '23:69' }

				it { is_expected.to be_nil }
			end
		end

		context 'number in seconds' do
			let(:value) { expectation.to_i }
			let(:expectation) { Time.new(2001, 1, 1, 11, 0) }

			it { is_expected.to eq expectation }
		end
	end

	describe '#to_boolean' do
		let(:type) { :boolean }

		it_behaves_like 'it parses nil', false
		it_behaves_like 'it parses empty string', true
		it_behaves_like 'it parses empty array', true
		it_behaves_like 'it parses empty hash', true

		context 'a value' do
			let(:value) { '42' }

			it { is_expected.to eq true }
		end

		context 'explicit false' do
			let(:value) { 'false' }

			it { is_expected.to eq false }
		end
	end

	describe '#to_symbol' do
		let(:type) { Symbol }

		it_behaves_like 'it parses nil'
		it_behaves_like 'it parses empty string', :''
	end

	describe '#to_date' do
		let(:type) { Date }

		it_behaves_like 'it parses nil'

		context 'string with some date' do
			let(:value) { '1.1.2001' }

			it { is_expected.to eql Date.new(2001, 1, 1) }
		end

		context 'string with malformed date' do
			let(:value) { '13.13.13' }

			it { is_expected.to be_nil }
		end
	end

	describe '#to_array' do
		let(:field_type) { [:array, of: type] }

		context 'of nothing' do
			let(:type) {}

			it_behaves_like 'it parses empty array', []
			it_behaves_like 'it parses empty hash', []
		end

		context 'of Integers' do
			let(:type) { Integer }

			it_behaves_like 'it parses empty array', []
			it_behaves_like 'it parses empty hash', []

			context 'array of some numbers' do
				let(:value) { %w[4 8 15 lol 16 23 42] }

				it { is_expected.to eql([4, 8, 15, nil, 16, 23, 42]) }
			end
		end
	end
end
