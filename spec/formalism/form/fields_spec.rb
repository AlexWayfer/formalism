# frozen_string_literal: true

describe Formalism::Form::Fields do
	before do
		stub_const('Inner', Struct.new(:name))

		stub_const(
			'InnerForm', Class.new(Formalism::Form) do
				field :name, String

				attr_reader :inner

				def initialize(*)
					super
					@inner = Inner.new(fields_and_nested_forms)
				end
			end
		)

		stub_const(
			'BaseModule', Module.new do
				include Formalism::Form::Fields

				field :foo

				nested :inner, InnerForm
			end
		)

		stub_const(
			'AnotherBaseModule', Module.new do
				include BaseModule

				field :bar, Integer
			end
		)

		stub_const(
			'MainForm', Class.new(Formalism::Form) do
				include AnotherBaseModule
			end
		)
	end

	let(:main_form) do
		MainForm.new(foo: 'foo', bar: '2', inner: { name: 'Alex' })
	end

	describe '.fields_and_nested_forms' do
		subject { MainForm.fields_and_nested_forms }

		it do
			is_expected.to eq(
				foo: { type: nil }, bar: { type: Integer },
				inner: {
					form: InnerForm,
					instance_variable: :inner,
					instance_variable_name: '@inner'
				}
			)
		end
	end

	describe '#fields' do
		subject { main_form.fields }

		it { is_expected.to eq(foo: 'foo', bar: 2) }
	end

	describe 'defaults' do
		before do
			stub_const(
				'InnerWithDefaultForm', Class.new(Formalism::Form) do
					field :name

					attr_reader :inner_with_default

					def initialize(*)
						super
						@inner_with_default = Inner.new(fields_and_nested_forms)
					end
				end
			)

			stub_const(
				'ModuleWithDefaults', Module.new do
					include Formalism::Form::Fields

					field :one
					field :two, default: 2

					nested :inner, InnerForm
					nested :inner_with_default, InnerWithDefaultForm, default: :entity
				end
			)

			stub_const(
				'FormWithDefaults', Class.new(Formalism::Form) do
					include ModuleWithDefaults

					field :three
					field :four, default: 4
				end
			)
		end

		subject(:form) { FormWithDefaults.new(params) }

		describe '#fields_and_nested_forms' do
			subject { super().send :fields_and_nested_forms }

			context 'with params' do
				let(:params) do
					{
						one: :first,
						two: :second,
						inner: { name: :regular },
						inner_with_default: { name: :another },
						three: :third,
						four: :fourth
					}
				end

				it do
					is_expected.to eq(
						one: :first,
						two: :second,
						inner: Inner.new(name: 'regular'),
						inner_with_default: Inner.new(name: :another),
						three: :third,
						four: :fourth
					)
				end
			end

			context 'without params' do
				let(:params) { {} }

				it do
					is_expected.to eq(
						two: 2,
						inner: Inner.new({}),
						inner_with_default: :entity,
						four: 4
					)
				end
			end
		end
	end
end
