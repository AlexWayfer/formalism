# frozen_string_literal: true

## This is unit test, created to simplify testing of different coercions
## You can find integration test in spec/formalism/form/fields_spec.rb
## (Formalism::Form -> .field -> coersion)
##
## In tests `eql` used instead of `eq` to determine result type
describe Formalism::Form::Coercion do
	describe '.method_for' do
		subject { described_class.method_for(type) }

		context 'with String argument' do
			let(:type) { 'boolean' }

			it { is_expected.to eq 'to_boolean' }

			context 'when String is upcased' do
				let(:type) { 'Boolean' }

				it { is_expected.to eq 'to_boolean' }
			end
		end

		context 'with Symbol argument' do
			let(:type) { :boolean }

			it { is_expected.to eq 'to_boolean' }

			context 'when Symbol is upcased' do
				let(:type) { :Boolean }

				it { is_expected.to eq 'to_boolean' }
			end
		end

		context 'with Class argument' do
			let(:type) { Integer }

			it { is_expected.to eq 'to_integer' }
		end
	end

	describe '.defined_for?' do
		subject { described_class.defined_for?(type) }

		context 'with supported type' do
			let(:type) { :boolean }

			it { is_expected.to be true }
		end

		context 'with unsupported type' do
			let(:type) { :unsupported }

			it { is_expected.to be false }
		end
	end

	describe '.convert_type' do
		subject { described_class.convert_type(type) }

		context 'without type' do
			let(:type) { nil }

			it { is_expected.to be_nil }
		end

		context 'with Class type' do
			let(:type) { Integer }

			it { is_expected.to eq Integer }
		end

		context 'with String type' do
			context 'when constant exists' do
				let(:type) { 'integer' }

				it { is_expected.to eq Integer }
			end

			context 'when constant does not exist' do
				let(:type) { 'nonexistent' }

				it { is_expected.to eq 'nonexistent' }
			end
		end

		context 'with Symbol type' do
			context 'when constant exists' do
				let(:type) { :integer }

				it { is_expected.to eq Integer }
			end

			context 'when constant does not exist' do
				let(:type) { :nonexistent }

				it { is_expected.to eq :nonexistent }
			end
		end
	end

	describe '.check' do
		subject(:check) { described_class.check(type, options) }

		let(:options) { {} }

		context 'with supported type' do
			let(:type) { :boolean }

			it { expect { check }.not_to raise_error }
		end

		context 'with unsupported type' do
			let(:type) { :unsupported }

			it { expect { check }.to raise_error(Formalism::Form::NoCoercionError) }
		end

		context 'with Array type' do
			let(:type) { Array }

			context 'without `:of` argument' do
				let(:options) { {} }

				it { expect { check }.not_to raise_error }
			end

			context 'with supported value of `:of` argument' do
				let(:options) { { of: Integer } }

				it { expect { check }.not_to raise_error }
			end

			context 'with unsupported value of `:of` argument' do
				let(:options) { { of: :unsupported } }

				it { expect { check }.to raise_error(Formalism::Form::NoCoercionError) }
			end
		end
	end

	describe '#result' do
		subject { described_class.new(value, type: type, of: of).result }

		# let(:value) { nil }
		let(:type) { [type] }
		let(:of) { nil }

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

		context 'with String type' do
			let(:type) { String }

			it_behaves_like 'it parses nil'
			it_behaves_like 'it parses empty string', ''
			it_behaves_like 'it parses empty array', '[]'
			it_behaves_like 'it parses empty hash', '{}'
		end

		context 'with Integer type' do
			let(:type) { Integer }

			it_behaves_like 'it parses nil'
			it_behaves_like 'it parses empty string'
			it_behaves_like 'it parses empty array'
			it_behaves_like 'it parses empty hash'

			context 'when number is String' do
				let(:value) { '42' }

				it { is_expected.to eq 42 }

				context 'when number is malformed' do
					let(:value) { '42 km' }

					it { is_expected.to be_nil }
				end
			end
		end

		context 'with Float type' do
			let(:type) { Float }

			it_behaves_like 'it parses nil'
			it_behaves_like 'it parses empty string'
			it_behaves_like 'it parses empty array'
			it_behaves_like 'it parses empty hash'

			context 'when number is String' do
				context 'without fraction' do
					let(:value) { '42' }

					it { is_expected.to eq 42.0 }
				end

				context 'with fraction' do
					let(:value) { '42.5' }

					it { is_expected.to eq 42.5 }
				end

				context 'when number is malformed' do
					let(:value) { '42 km' }

					it { is_expected.to be_nil }
				end
			end
		end

		context 'with Time type' do
			let(:type) { Time }

			it_behaves_like 'it parses nil'

			context 'when time is String' do
				context 'with time' do
					let(:value) { '1.1.2001 11:00' }

					it { is_expected.to eq Time.new(2001, 1, 1, 11, 0) }
				end

				context 'when time is malformed' do
					context 'when hours' do
						let(:value) { '25:00' }

						it { is_expected.to be_nil }
					end

					context 'when minutes' do
						let(:value) { '23:69' }

						it { is_expected.to be_nil }
					end
				end
			end

			context 'when time is Integer in seconds' do
				let(:value) { expectation.to_i }
				let(:expectation) { Time.new(2001, 1, 1, 11, 0) }

				it { is_expected.to eq expectation }
			end
		end

		context 'with Boolean type' do
			let(:type) { :boolean }

			it_behaves_like 'it parses nil', false
			it_behaves_like 'it parses empty string', true
			it_behaves_like 'it parses empty array', true
			it_behaves_like 'it parses empty hash', true

			context 'when value is non-booblean String' do
				let(:value) { '42' }

				it { is_expected.to eq true }
			end

			context 'when value is boolean String' do
				let(:value) { 'false' }

				it { is_expected.to eq false }
			end
		end

		context 'with Symbol type' do
			let(:type) { Symbol }

			it_behaves_like 'it parses nil'
			it_behaves_like 'it parses empty string', :''
		end

		context 'with Date type' do
			let(:type) { Date }

			it_behaves_like 'it parses nil'

			context 'when date is String' do
				let(:value) { '1.1.2001' }

				it { is_expected.to eql Date.new(2001, 1, 1) }

				context 'when date is malformed' do
					let(:value) { '13.13.13' }

					it { is_expected.to be_nil }
				end
			end
		end

		context 'with Array type' do
			let(:type) { Array }

			context 'without :of' do
				let(:of) {}

				it_behaves_like 'it parses empty array', []
				it_behaves_like 'it parses empty hash', []

				context 'when Array of some numbers as strings' do
					let(:value) { %w[4 8 15 lol 16 23 42] }

					it { is_expected.to be value }
				end
			end

			context 'with :of as Integer' do
				let(:of) { Integer }

				it_behaves_like 'it parses empty array', []
				it_behaves_like 'it parses empty hash', []

				context 'when Array of some numbers as strings' do
					let(:value) { %w[4 8 15 lol 16 23 42] }

					it { is_expected.to eq [4, 8, 15, nil, 16, 23, 42] }
				end
			end
		end

		context 'with Hash type' do
			let(:type) { Hash }

			it_behaves_like 'it parses empty array', {}
			it_behaves_like 'it parses empty hash', {}

			context 'when Hash of Symbol -> String' do
				let(:value) { { foo: 'bar', baz: 'qux' } }

				it { is_expected.to be value }
			end
		end
	end
end
