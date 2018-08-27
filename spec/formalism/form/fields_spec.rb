# frozen_string_literal: true

describe Formalism::Form::Fields do
	before do
		stub_const(
			'InnerForm', Class.new(Formalism::Form) do
				field :name, String
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
				inner: { form: InnerForm, instance_variable: :inner }
			)
		end
	end

	describe '#fields' do
		subject { main_form.fields }

		it { is_expected.to eq(foo: 'foo', bar: 2) }
	end
end
