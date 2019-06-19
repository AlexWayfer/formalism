# frozen_string_literal: true

describe Formalism::Form::Fields do
	Inner = Struct.new(:name)

	class InnerForm < Formalism::Form
		field :name, String

		## https://github.com/rubocop-hq/rubocop-rspec/issues/750
		# rubocop:disable RSpec/InstanceVariable
		def initialize(*args)
			super

			return if defined?(@instance)

			@instance = Inner.new(fields_and_nested_forms)
		end
		# rubocop:enable RSpec/InstanceVariable
	end

	module BaseModule
		include Formalism::Form::Fields

		field :foo

		nested :inner, InnerForm
	end

	module AnotherBaseModule
		include BaseModule

		field :bar, Integer
	end

	class MainForm < Formalism::Form
		include AnotherBaseModule
	end

	let(:main_form) do
		MainForm.new(foo: 'foo', bar: '2', inner: { name: 'Alex' })
	end

	describe '.fields_and_nested_forms' do
		subject { MainForm.fields_and_nested_forms }

		let(:result_hash) do
			{
				foo: { type: nil },
				bar: { type: Integer },
				inner: {
					form: InnerForm
				}
			}
		end

		it { is_expected.to eq result_hash }
	end

	describe '#fields' do
		subject { main_form.fields }

		it { is_expected.to eq(foo: 'foo', bar: 2) }
	end

	describe '#fields_and_nested_forms' do
		subject { form.send :fields_and_nested_forms }

		describe 'defaults' do
			class InnerWithDefaultForm < Formalism::Form
				field :name

				## https://github.com/rubocop-hq/rubocop-rspec/issues/750
				# rubocop:disable RSpec/InstanceVariable
				def initialize(*args)
					super

					return if defined?(@instance)

					@instance = Inner.new(fields_and_nested_forms)
				end
				# rubocop:enable RSpec/InstanceVariable
			end

			module ModuleWithDefaults
				include Formalism::Form::Fields

				field :one
				field :two, default: 2

				nested :inner, InnerForm
				nested :inner_with_default, InnerWithDefaultForm, default: :entity
			end

			class FormWithDefaults < Formalism::Form
				include ModuleWithDefaults

				field :three
				field :four, default: 4
			end

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

			let(:result_with_params) do
				{
					one: :first,
					two: :second,
					inner: Inner.new(name: 'regular'),
					inner_with_default: Inner.new(name: :another),
					three: :third,
					four: :fourth
				}
			end

			let(:result_without_params) do
				{
					two: 2,
					inner: Inner.new({}),
					inner_with_default: :entity,
					four: 4
				}
			end

			context 'when regular' do
				let(:form) { FormWithDefaults.new(params) }

				context 'with params' do
					it { is_expected.to eq result_with_params }
				end

				context 'without params' do
					let(:params) { {} }

					it { is_expected.to eq result_without_params }
				end
			end

			context 'with refined options for .field and .nested' do
				class FormWithRefinedDefaults < Formalism::Form
					class << self
						%i[field nested].each do |method_name|
							define_method method_name do |name, type_or_form = nil, **options|
								options[:default] =
									options.fetch(:default, -> { :refined_default })

								super(name, type_or_form, **options)
							end
						end
					end

					include ModuleWithDefaults

					field :three
					field :four, default: 4
				end

				let(:form) { FormWithRefinedDefaults.new(params) }

				context 'with params' do
					it { is_expected.to eq result_with_params }
				end

				context 'without params' do
					let(:params) { {} }

					let(:result_without_params) do
						{
							one: :refined_default,
							two: 2,
							inner: :refined_default,
							inner_with_default: :entity,
							three: :refined_default,
							four: 4
						}
					end

					it { is_expected.to eq result_without_params }
				end
			end
		end

		describe 'redefined accessors' do
			before do
				stub_const(
					'FormWithRedefinedAccessors', Class.new(Formalism::Form) do
						field :foo, Symbol
						field :status, Symbol

						private

						def status=(value)
							super unless value == 'all'
						end
					end
				)
			end

			let(:form) { FormWithRedefinedAccessors.new(params) }

			context "with 'all' status (don't call `super`)" do
				let(:params) { { foo: 'bar', status: 'all' } }

				it { is_expected.to eq foo: :bar }
			end

			context 'with another status (call `super`)' do
				let(:params) { { foo: 'bar', status: 'activated' } }

				it { is_expected.to eq foo: :bar, status: :activated }
			end
		end
	end
end
