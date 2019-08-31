# frozen_string_literal: true

describe Formalism::Form::Fields do
	before do
		stub_const 'Inner', Struct.new(:name)
	end

	let(:inner_form_class) do
		Class.new(Formalism::Form) do
			field :name, String

			def initialize(*args)
				super

				return if defined?(@instance)

				@instance = Inner.new(fields_and_nested_forms)
			end
		end
	end

	let(:base_module) do
		inner_form_class = self.inner_form_class

		Module.new do
			include Formalism::Form::Fields

			field :foo

			nested :inner, inner_form_class
		end
	end

	let(:another_base_module) do
		base_module = self.base_module

		Module.new do
			include base_module

			field :bar, Integer
		end
	end

	let(:main_form_class) do
		another_base_module = self.another_base_module

		Class.new(Formalism::Form) do
			include another_base_module
		end
	end

	let(:main_form) do
		main_form_class.new(foo: 'foo', bar: '2', inner: { name: 'Alex' })
	end

	describe '.fields_and_nested_forms' do
		subject { main_form_class.fields_and_nested_forms }

		let(:result_hash) do
			{
				foo: { type: nil },
				bar: { type: Integer },
				inner: {
					form: inner_form_class
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
			let(:inner_with_default_form_class) do
				Class.new(Formalism::Form) do
					field :name

					def initialize(*args)
						super

						return if defined?(@instance)

						@instance = Inner.new(fields_and_nested_forms)
					end
				end
			end

			let(:module_with_defaults) do
				inner_form_class = self.inner_form_class
				inner_with_default_form_class = self.inner_with_default_form_class

				Module.new do
					include Formalism::Form::Fields

					field :one
					field :two, default: 2

					nested :inner, inner_form_class
					nested :inner_with_default, inner_with_default_form_class,
						default: :entity
				end
			end

			let(:form_with_defaults_class) do
				module_with_defaults = self.module_with_defaults

				Class.new(Formalism::Form) do
					include module_with_defaults

					field :three
					field :four, default: 4
				end
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
				let(:form) { form_with_defaults_class.new(params) }

				context 'with params' do
					it { is_expected.to eq result_with_params }
				end

				context 'without params' do
					let(:params) { {} }

					it { is_expected.to eq result_without_params }
				end
			end

			context 'with refined options for .field and .nested' do
				let(:form_with_refined_defaults_class) do
					module_with_defaults = self.module_with_defaults

					Class.new(Formalism::Form) do
						class << self
							%i[field nested].each do |method_name|
								define_method(
									method_name
								) do |name, type_or_form = nil, **options|
									options[:default] =
										options.fetch(:default, -> { :refined_default })

									super(name, type_or_form, **options)
								end
							end
						end

						include module_with_defaults

						field :three
						field :four, default: 4
					end
				end

				let(:form) { form_with_refined_defaults_class.new(params) }

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
			let(:form_with_redefined_accessors_class) do
				Class.new(Formalism::Form) do
					field :foo, Symbol
					field :status, Symbol

					private

					def status=(value)
						super unless value == 'all'
					end
				end
			end

			let(:form) { form_with_redefined_accessors_class.new(params) }

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
