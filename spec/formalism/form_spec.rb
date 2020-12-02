# frozen_string_literal: true

describe Formalism::Form do
	subject(:album_form) { album_form_class.new(params) }

	before do
		stub_const 'YEAR_RANGE', 0..Time.now.year

		stub_const(
			'Model', Class.new(Struct) do
				attr_reader :id

				def self.all
					@all ||= []
				end

				def self.create(params)
					new(params).save
				end

				def self.find(params)
					all.find do |record|
						params.all? { |key, value| record.public_send(key) == value }
					end
				end

				def self.find_or_create(params)
					find(params) || new(params).save
				end

				def initialize(columns)
					columns.each do |column, value|
						public_send "#{column}=", value
					end
				end

				def id=(_value)
					raise ArgumentError, 'id is a restricted primary key'
				end

				def save
					all = self.class.all
					@id ||= all.last&.id.to_i.next
					all.delete_if { |record| record.id == id }
					all.push self
					self
				end
			end
		)

		stub_const(
			'Album', Model.new(
				:title, :year, :artist, :tag, :label, :genre, :producer
			)
		)
	end

	let(:album_form_class) do
		Class.new(described_class) do
			field :id, Integer, merge: false
			field :title
			field :year, Integer

			private

			def validate
				errors.add('Album title is not present') if title.to_s.empty?

				return if YEAR_RANGE.include? year

				errors.add("Album year is not in #{YEAR_RANGE}")
			end

			def execute
				@instance = Album.create(fields_and_nested_forms)
			end
		end
	end

	let(:correct_album_params) { { title: 'Foo', year: 2018 } }
	let(:incorrect_album_params) { { year: 3018 } }

	let(:form) { form_class.new(params) }

	after do
		ObjectSpace.each_object(Class).each do |model|
			next unless model < Model

			model.all.clear
		end
	end

	shared_examples 'there are no Albums' do
		before do
			form_run
		end

		describe 'all Albums' do
			subject { Album.all }

			it { is_expected.to be_empty }
		end
	end

	shared_examples 'there is one Album' do
		before do
			form_run
		end

		describe 'all Albums' do
			subject { Album.all }

			it { is_expected.to eq [album] }
		end
	end

	describe '.field' do
		subject { form.fields }

		let(:form_class) do
			Class.new(described_class) do
				field :id, Integer, merge: false
				field :foo
				field :bar, Integer
				field :baz, String
				field :created_at, Time
				field :release_date, Date
				field :count, :integer
				field :price, Float
				field :enabled, :boolean
				field :status, Symbol
				field :tags, Array
				field :ids, Array, of: Integer

				private

				def execute
					@instance =
						Model.new(:foo, :bar).create(fields_and_nested_forms)
				end
			end
		end

		let(:not_coerced_time) { '2018-05-03 14:02:21' }

		let(:not_coerced_params) do
			{
				foo: '1',
				bar: '2',
				baz: 3,
				count: '-0123',
				price: '+00456.789',
				status: 'activated',
				tags: 1..3,
				ids: ['04', 5, '6'],
				release_date: '1.1.2001'
			}
		end

		let(:coerced_time) { Time.new(2018, 5, 3, 14, 2, 21) }

		let(:coerced_params) do
			{
				foo: '1',
				bar: 2,
				baz: '3',
				count: -123,
				price: 456.789,
				status: :activated,
				tags: [1, 2, 3],
				ids: [4, 5, 6],
				release_date: Date.new(2001, 1, 1)
			}
		end

		describe 'filtering input params for' do
			let(:form_class) do
				Class.new(described_class) do
					field :foo
					field :bar
				end
			end

			let(:params) { { foo: 1, bar: 2, baz: 3 } }

			it { is_expected.to eq(foo: 1, bar: 2) }
		end

		describe 'coercion' do
			context 'when params must be coerced' do
				let(:params) { not_coerced_params.merge(qux: 4) }

				it { is_expected.to eq coerced_params }

				it 'returns coerced values from getters' do
					coerced_params.each do |name, value|
						expect(form.public_send(name)).to eq(value)
					end
				end
			end

			context 'when params must not be coerced' do
				let(:params) { coerced_params.merge(qux: 4) }

				it { is_expected.to eq coerced_params }
			end

			describe 'to Time' do
				let(:coerced_time_params) { { created_at: coerced_time } }

				context 'when value is String' do
					let(:params) { { created_at: not_coerced_time } }

					it { is_expected.to eq(coerced_time_params) }
				end

				context 'when value is Time' do
					let(:params) { coerced_time_params }

					it { is_expected.to eq(coerced_time_params) }
				end

				context 'when value is nil' do
					let(:params) { { created_at: nil } }

					it { is_expected.to eq(created_at: nil) }
				end
			end

			describe 'to boolean' do
				context "when value is 'true'" do
					let(:params) { { enabled: 'true' } }

					it { is_expected.to eq(enabled: true) }
				end

				context 'when value is true' do
					let(:params) { { enabled: true } }

					it { is_expected.to eq(enabled: true) }
				end

				context 'when value is false' do
					let(:params) { { enabled: false } }

					it { is_expected.to eq(enabled: false) }
				end

				context 'when value is nil' do
					let(:params) { { enabled: nil } }

					it { is_expected.to eq(enabled: false) }
				end

				context "when value is 'false'" do
					let(:params) { { enabled: 'false' } }

					it { is_expected.to eq(enabled: false) }
				end
			end

			describe 'error if there is no defined coercion to the required type' do
				shared_examples 'raise error' do
					it do
						expect { subject }.to raise_error(
							Formalism::Form::NoCoercionError,
							'Formalism has no coercion to Module'
						)
					end
				end

				context 'with regular type of field' do
					subject do
						Class.new(described_class) do
							field :foo
							field :bar, Module
						end
					end

					it_behaves_like 'raise error'
				end

				context 'with Array type' do
					subject do
						Class.new(described_class) do
							field :foo
							field :bar, Array, of: Module
						end
					end

					it_behaves_like 'raise error'
				end
			end
		end

		describe ':default option' do
			default_created_at = Time.new(2018, 5, 7, 14, 40)

			let(:form_class) do
				Class.new(described_class) do
					field :foo
					field :bar, Integer, default: nil
					field :baz, String, default: 'qwerty'
					field :name, String, default: nil
					field :created_at, Time, default: (
						lambda do
							@default_called = true
							default_created_at
						end
					)
					field :updated_at, Time, default: -> { created_at }
					field :count, :integer, default: 0
					field :price, Float, default: 2.5
					field :enabled, :boolean, default: false
					field :status, Symbol, default: :all
					field :release_date, Date, default: -> { Date.new(2002, 1, 1) }
					field :tags, Array, default: [:world]
					field :ids, Array, of: Integer, default: [7, 8]

					attr_reader :default_called

					def initialize(params, set_count: false)
						self.count = 2 if set_count

						super params
					end
				end
			end

			let(:form) { form_class.new(params, set_count: set_count) }
			let(:set_count) { false }

			context 'when params is filled' do
				let(:params) do
					not_coerced_params.merge(
						name: 'Alex',
						created_at: not_coerced_time,
						updated_at: '2018-05-07 21:49',
						enabled: 'true',
						qux: 4
					)
				end

				let(:coreced_result) do
					coerced_params.merge(
						name: 'Alex',
						created_at: coerced_time,
						updated_at: Time.new(2018, 5, 7, 21, 49),
						enabled: true
					)
				end

				it { is_expected.to eq coreced_result }

				describe '@default_called' do
					subject { form.default_called }

					it { is_expected.to be_nil }
				end
			end

			context 'when params is empty' do
				let(:params) { {} }
				let(:empty_result) do
					{
						bar: nil,
						baz: 'qwerty',
						name: nil,
						created_at: default_created_at,
						updated_at: default_created_at,
						count: 0,
						price: 2.5,
						enabled: false,
						status: :all,
						tags: [:world],
						ids: [7, 8],
						release_date: Date.new(2002, 1, 1)
					}
				end

				it { is_expected.to eq empty_result }

				describe '@default_called' do
					subject { form.default_called }

					it { is_expected.to be true }
				end
			end

			context 'when field set in initializer before super' do
				subject { super()[:count] }

				let(:set_count) { true }

				context 'when params is filled' do
					let(:params) { not_coerced_params }

					it { is_expected.to eq coerced_params[:count] }
				end

				context 'when params is empty' do
					let(:params) { {} }

					it { is_expected.to eq 2 }
				end
			end
		end

		describe ':key option' do
			let(:form_class) do
				Class.new(described_class) do
					field :foo, key: :bar
					field :bar
					field :baz, key: :foo
				end
			end

			let(:params) { { foo: 'foo', bar: 'bar', baz: 'baz' } }

			it { is_expected.to eq(foo: 'bar', bar: 'bar', baz: 'foo') }
		end

		describe 'inheritance' do
			let(:parent_form_class) do
				Class.new(described_class) do
					field :foo
					field :qux
				end
			end

			let(:form_class) do
				Class.new(parent_form_class) do
					field :bar
				end
			end

			let(:params) do
				{ foo: 1, bar: '2', baz: Time.now, qux: [], quux: 'what?' }
			end

			it { is_expected.to eq(foo: 1, bar: '2', qux: []) }

			describe '.remove_field' do
				let(:form_class) do
					result = super()
					result.instance_exec do
						remove_field :qux

						field :quux
						remove_field :quux
					end
					result
				end

				it { is_expected.to eq(foo: 1, bar: '2') }

				describe 'methods of removed fields' do
					subject { form_class.method_defined?(:quux) }

					it { is_expected.to be false }

					describe 'child form has no methods of removed fields' do
						let(:form_class) do
							Class.new super()
						end

						it { is_expected.to be false }
					end
				end

				describe 'it left methods of removed fields in parent' do
					subject { form_class.superclass.method_defined?(:qux) }

					it { is_expected.to be true }
				end
			end
		end

		describe ':merge option' do
			subject { form.send(:fields_and_nested_forms) }

			let(:nested_form_class) do
				Class.new(described_class) do
					field :number

					def instance
						number * 2
					end

					private

					def validate
						return if number == 42

						errors.add 'Number is not correct.'
					end
				end
			end

			let(:form_class) do
				nested_form_class = self.nested_form_class

				Class.new(described_class) do
					field :foo
					field :bar, merge: true
					field :baz, merge: false
					field :qux, merge: proc { baz == 5 }
					nested :nested, nested_form_class, merge: ->(form) { form.valid? }

					private

					def execute
						@instance = Model.new(:foo, :bar).create(fields_and_nested_forms)
					end
				end
			end

			context 'without params' do
				let(:params) { {} }

				it { is_expected.to eq({}) }
			end

			context 'with params' do
				let(:params) do
					{ foo: 1, bar: 2, baz: baz, qux: 4, nested: { number: number } }
				end

				context 'when lambda returns `false`' do
					let(:baz) { 3 }
					let(:number) { 2 }

					it { is_expected.to eq foo: 1, bar: 2 }
				end

				context 'when lambda returns `true`' do
					let(:baz) { 5 }
					let(:number) { 42 }

					it { is_expected.to eq foo: 1, bar: 2, qux: 4, nested: 84 }
				end
			end
		end

		describe 'values from params is more important than from @instance' do
			let(:form_class) do
				Class.new(described_class) do
					field :foo

					def initialize(params)
						@instance = Struct.new(:foo).new(:from_instance)

						super
					end
				end
			end

			let(:params) { { foo: :from_params } }

			it { is_expected.to eq(foo: :from_params) }
		end
	end

	describe '#fields' do
		subject { album_form.fields }

		context 'with not enough params' do
			let(:params) { { title: 'Foo' } }

			it { is_expected.to eq(title: 'Foo') }
		end

		context 'with enough params' do
			let(:params) { correct_album_params }

			it { is_expected.to eq(correct_album_params) }
		end

		context 'with more than enough params' do
			let(:params) { correct_album_params.merge(artist: 'Bar') }

			it { is_expected.to eq(correct_album_params) }
		end
	end

	describe '#valid?' do
		subject { album_form.valid? }

		context 'with correct params' do
			let(:params) { correct_album_params }

			it { is_expected.to be true }
		end

		context 'with incorrect params' do
			let(:params) { incorrect_album_params }

			it { is_expected.to be false }
		end
	end

	describe '#run' do
		subject(:form_run) { album_form.run }

		describe '#success?' do
			subject { super().success? }

			context 'with correct params' do
				let(:params) { correct_album_params }

				it { is_expected.to be true }
			end

			context 'with incorrect params' do
				let(:params) { incorrect_album_params }

				it { is_expected.to be false }
			end
		end

		describe '#errors' do
			subject(:errors) { form_run.errors }

			context 'with correct params' do
				let(:params) { correct_album_params }

				it { is_expected.to be_empty }
			end

			context 'with incorrect params' do
				let(:params) { incorrect_album_params }

				it do
					expect(errors).to eq [
						'Album title is not present',
						"Album year is not in #{YEAR_RANGE}"
					].to_set
				end
			end
		end

		describe '#result' do
			subject(:result) { form_run.result }

			context 'with correct params' do
				let(:params) { correct_album_params }
				let(:album) { Album.new(params) }

				it { is_expected.to eq Album.new(params) }

				include_examples 'there is one Album'
			end

			context 'with incorrect params' do
				let(:params) { incorrect_album_params }
				let(:error_message) do
					<<~MESSAGE.chomp
						Outcome has errors: ["Album title is not present", "Album year is not in #{YEAR_RANGE}"]
					MESSAGE
				end

				include_examples 'there are no Albums'

				it do
					expect { result }
						.to raise_error Formalism::Form::ValidationError, error_message
				end
			end
		end
	end

	describe '.nested' do
		before do
			stub_const 'Artist', Model.new(:name)
			stub_const 'Tag', Model.new(:name)
			stub_const 'Label', Model.new(:name)
		end

		let(:artist_form_class) do
			Class.new(described_class) do
				field :name

				private

				def validate
					return unless name.to_s.empty?

					errors.add('Artist name is not present')
				end

				def execute
					@instance = Artist.find_or_create(fields_and_nested_forms)
				end
			end
		end

		let(:tag_form_class) do
			Class.new(described_class) do
				field :name, String

				private

				def validate
					return unless name.to_s.empty?

					errors.add('Tag name is not present')
				end

				def execute
					@instance = Tag.find_or_create(fields_and_nested_forms)
				end
			end
		end

		let(:label_form_class) do
			Class.new(described_class) do
				def initialize(name)
					@name = name
					super({})
				end

				private

				def execute
					@instance = Label.find_or_create(name: @name)
				end
			end
		end

		let(:compositor_form_class) do
			Class.new(described_class) do
				field :name

				private

				def validate
					return unless name.to_s.empty?

					errors.add('Compositor name is not present')
				end

				def execute
					@instance = Compositor.find_or_create(fields_and_nested_forms)
				end
			end
		end

		let(:producer_form_class) do
			artist_form_class = self.artist_form_class

			Class.new(described_class) do
				extend Forwardable

				def_delegator :artist_form, :instance

				field :name

				nested :artist, artist_form_class,
					initialize: ->(form) { form.new(fields_and_nested_forms) },
					errors_key: nil

				private

				def execute
					artist_form.run
				end
			end
		end

		let(:album_with_nested_form_class) do
			artist_form_class = self.artist_form_class
			tag_form_class = self.tag_form_class
			label_form_class = self.label_form_class
			compositor_form_class = self.compositor_form_class
			producer_form_class = self.producer_form_class

			Class.new(album_form_class) do
				nested :artist, artist_form_class

				nested :tag, tag_form_class, default: -> { default_tag }

				nested :label, label_form_class,
					initialize: ->(form) { form.new(params[:label_name]) }

				field :genre, default: -> { label }

				nested :compositor, initialize: (
					proc do
						(artist_form.valid? ? artist_form_class : compositor_form_class)
							.new(params[artist_form.valid? ? :artist : :compositor])
					end
				), merge: false

				nested :update_something, initialize: ->(_form) {}

				nested :hashtag, tag_form_class, merge: false

				nested :producer, producer_form_class

				private

				def execute
					artist_form.run
					tag_form.run
					label_form.run
					producer_form.run
					super
				end

				def default_tag
					Tag.new(name: 'default')
				end
			end
		end

		let(:album_with_nested_form) { album_with_nested_form_class.new(params) }

		context 'without form and :initialize parameters' do
			it do
				expect { album_with_nested_form_class.nested :incorrect_form }
					.to raise_error(
						ArgumentError,
						'Neither form class nor initialize block is not present'
					)
			end
		end

		describe '#valid?' do
			subject { album_with_nested_form.valid? }

			context 'with correct params' do
				let(:params) do
					correct_album_params.merge(
						artist: { name: 'Bar' }, producer: { name: 'Producer' },
						hashtag: { name: '#cool' }
					)
				end

				it { is_expected.to be true }
			end

			context 'with incorrect params' do
				let(:params) { correct_album_params.merge(artist: { name: '' }) }

				it { is_expected.to be false }
			end
		end

		describe '#run' do
			subject(:form_run) { album_with_nested_form.run }

			let(:correct_album_with_nested_forms_params) do
				correct_album_params.merge(
					artist: { name: 'Bar' }, tag: { name: 'Blues' },
					label_name: 'RAM', producer: { name: 'Producer' },
					hashtag: { name: '#cool' }
				)
			end

			shared_examples 'global data is empty' do
				before do
					form_run
				end

				include_examples 'there are no Albums'

				describe 'all Artists' do
					subject { Artist.all }

					it { is_expected.to be_empty }
				end

				describe 'all Labels' do
					subject { Label.all }

					it { is_expected.to be_empty }
				end

				describe 'all Tags' do
					subject { Tag.all }

					it { is_expected.to be_empty }
				end
			end

			shared_examples 'global data is not empty' do
				before do
					form_run
				end

				let(:album) do
					Album.new(
						correct_album_params.merge(
							artist: artist, tag: tag, label: label, producer: producer
						)
					)
				end

				let(:artist) { Artist.new(name: 'Bar') }
				let(:tag) { Tag.new(name: 'Blues') }
				let(:label) { Label.new(name: 'RAM') }
				let(:producer) { Artist.new(name: 'Producer') }

				include_examples 'there is one Album'

				describe 'all Artists' do
					subject { Artist.all }

					it { is_expected.to eq [artist, producer] }
				end

				describe 'all Labels' do
					subject { Label.all }

					it { is_expected.to eq [label] }
				end

				describe 'all Tags' do
					subject { Tag.all }

					it { is_expected.to eq [tag] }
				end
			end

			describe '#success?' do
				subject { super().success? }

				context 'with correct params' do
					let(:params) { correct_album_with_nested_forms_params }

					it { is_expected.to be true }

					include_examples 'global data is not empty'
				end

				context 'with incorrect params' do
					let(:params) { { title: '', year: 2018, artist: { name: '' } } }

					it { is_expected.to be false }

					include_examples 'global data is empty'
				end
			end

			describe '#errors' do
				subject { super().errors }

				context 'with correct params' do
					let(:params) { correct_album_with_nested_forms_params }

					it { is_expected.to be_empty }

					include_examples 'global data is not empty'
				end

				context 'with incorrect params' do
					let(:params) { { title: '', year: 2018, artist: { name: '' } } }
					let(:result_errors) do
						[
							'Album title is not present', 'Artist name is not present',
							'Compositor name is not present', 'Tag name is not present'
						].to_set
					end

					it { is_expected.to eq result_errors }

					include_examples 'global data is empty'
				end
			end

			describe 'values from params is more important than from @instance' do
				subject { form_class.new(params).send :fields_and_nested_forms }

				let(:inner_form_class) do
					Class.new(described_class)
				end

				let(:form_class) do
					inner_form_class = self.inner_form_class

					Class.new(described_class) do
						nested :inner_form, inner_form_class

						def initialize(params)
							@instance = Struct.new(:inner_form).new(:from_instance)

							super
						end
					end
				end

				let(:params) { { inner_form: :from_params } }

				it { is_expected.to eq(inner_form: :from_params) }
			end
		end

		describe ':depends_on option' do
			subject { form_class.new(params).send :fields_and_nested_forms }

			let(:bar_form_class) do
				Class.new(described_class) do
					class << self
						attr_writer :initialized_times

						def initialized_times
							@initialized_times ||= 0
						end
					end

					def initialize(*)
						self.class.initialized_times += 1

						super
					end
				end
			end

			let(:form_class) do
				bar_form_class = self.bar_form_class

				Class.new(described_class) do
					field :foo, default: -> { bar }, depends_on: :bar
					nested :bar, bar_form_class
					field :baz, default: -> { bar * qux }, depends_on: %i[bar qux]
					field :qux
					field :quxx, depends_on: :attribute
				end
			end

			let(:params) { { bar: 2, qux: 4 } }

			it { is_expected.to eq(foo: 2, bar: 2, baz: 8, qux: 4) }

			describe 'filling times' do
				subject { bar_form_class.initialized_times }

				before do
					form
				end

				it { is_expected.to eq 1 }
			end
		end

		describe ':merge_errors option' do
			subject { form.run.errors }

			let(:bar_form_class) do
				Class.new(described_class) do
					private

					def validate
						errors.add "I'm always dissatisfied"
					end

					def execute; end
				end
			end

			let(:base_class) do
				Class.new(described_class) do
					private

					def execute; end
				end
			end

			let(:params) { nil }

			let(:non_empty_errors) { Set["I'm always dissatisfied"] }

			context 'when default' do
				let(:form_class) do
					bar_form_class = self.bar_form_class

					Class.new(base_class) do
						nested :bar, bar_form_class
					end
				end

				it { is_expected.to eq non_empty_errors }
			end

			context 'when true' do
				let(:form_class) do
					bar_form_class = self.bar_form_class

					Class.new(base_class) do
						nested :bar, bar_form_class, merge_errors: true
					end
				end

				it { is_expected.to eq non_empty_errors }
			end

			context 'when false' do
				let(:form_class) do
					bar_form_class = self.bar_form_class

					Class.new(base_class) do
						nested :bar, bar_form_class, merge_errors: false
					end
				end

				it { is_expected.to be_empty }
			end

			context 'when proc' do
				let(:form_class) do
					bar_form_class = self.bar_form_class

					Class.new(base_class) do
						nested :bar, bar_form_class, merge_errors: -> { @should_merge_bar }

						def initialize(params, should_merge_bar)
							super params

							@should_merge_bar = should_merge_bar
						end
					end
				end

				let(:form) { form_class.new(params, should_merge_bar) }

				context 'when true' do
					let(:should_merge_bar) { true }

					it { is_expected.to eq non_empty_errors }
				end

				context 'when false' do
					let(:should_merge_bar) { false }

					it { is_expected.to be_empty }
				end
			end
		end

		describe '#to_params' do
			subject { album_with_nested_form.to_params }

			context 'with correct params' do
				let(:params) do
					correct_album_params.merge(
						artist: { name: 'Bar' }, producer: { name: 'Producer' },
						hashtag: { name: '#cool' }
					)
				end

				let(:expected_result) do
					{
						artist: { name: 'Bar' },
						compositor: { name: 'Bar' },
						genre: nil,
						hashtag: { name: '#cool' },
						label: {},
						producer: { artist: { name: 'Producer' }, name: 'Producer' },
						tag: { name: 'default' },
						title: 'Foo',
						year: 2018
					}
				end

				it { is_expected.to eq expected_result }
			end

			context 'with incorrect params' do
				let(:params) { correct_album_params.merge(artist: { name: '' }) }

				let(:expected_result) do
					{
						artist: { name: '' },
						compositor: {},
						genre: nil,
						hashtag: {},
						label: {},
						producer: { artist: {} },
						tag: { name: 'default' },
						title: 'Foo',
						year: 2018
					}
				end

				it { is_expected.to eq expected_result }
			end
		end
	end

	describe ':runnable' do
		let(:location_form_class) do
			Class.new(described_class) do
				field :address

				private

				def validate
					errors.add 'Empty address' if address.to_s.empty?
				end

				def execute
					{ address: address }
				end
			end
		end

		let(:form_class) do
			location_form_class = self.location_form_class

			Class.new(described_class) do
				field :name
				nested :location, location_form_class

				def initialize(params, runnable)
					self.runnable = runnable

					super params
				end

				private

				def validate
					errors.add 'Empty name' if name.to_s.empty?
				end

				def execute
					{ name: name, location: location_form.run }
				end
			end
		end

		let(:form) { form_class.new(params, runnable) }

		let(:params) do
			{ name: 'Alexander', location: { address: 'Moscow' } }
		end

		let(:valid_outcome) do
			nested_forms =
				params.slice(:location).transform_values { |hash| have_attributes(result: hash) }
			have_attributes result: params.merge(nested_forms)
		end

		describe '#valid?' do
			subject { form.valid? }

			context 'when runnable' do
				let(:runnable) { true }

				it { is_expected.to be true }
			end

			context 'when not runnable' do
				let(:runnable) { false }

				it { is_expected.to be_nil }
			end
		end

		describe '#run' do
			subject { form.run }

			context 'when runnable' do
				let(:runnable) { true }

				it { is_expected.to valid_outcome }
			end

			context 'when not runnable' do
				let(:runnable) { false }

				it { is_expected.to be_nil }

				describe 'nested form' do
					subject { form.location_form.run }

					it { is_expected.to be_nil }
				end
			end
		end
	end

	describe 'redefinition methods for filling from params' do
		let(:user_class) { Model.new(:name, :role) }
		let(:article_class) { Model.new(:title, :author) }

		let(:author_form_class) do
			Class.new(described_class) do
				field :name, String
				field :role
			end
		end

		let(:form_class) do
			author_form_class = self.author_form_class

			Class.new(described_class) do
				nested :author, author_form_class

				private

				def params_for_nested_author
					super.merge(role: :regular)
				end
			end
		end

		describe '`author` nested form' do
			describe '`:role` field' do
				subject { form.author_form.role }

				let(:correct_role) { :regular }

				context 'when initialized by Hash' do
					let(:params) { { title: 'New post', author: { name: 'Alexander' } } }

					it { is_expected.to eq correct_role }
				end

				context 'when initialized by instance' do
					let(:role) { :admin }
					let(:params) do
						article_class.new(
							title: 'New post',
							author: user_class.new(name: 'Alexander', role: role)
						)
					end

					it { is_expected.to eq role }
				end
			end
		end

		context 'when defined in module before any definition of nesting form' do
			let(:book_form_class) do
				Class.new(described_class) do
					field :titile, String
					field :published
				end
			end

			let(:book_module) do
				book_form_class = self.book_form_class

				Module.new do
					include Formalism::Form::Fields

					nested :book, book_form_class

					private

					def params_for_nested_book
						super.merge(published: true)
					end
				end
			end

			before do
				form_class.include book_module
			end

			describe '`:published` field' do
				subject { form.book_form.published }

				let(:params) { { title: 'New post', book: { title: 'Cool' } } }

				it { is_expected.to be true }
			end
		end
	end

	describe 'redefine methods for filling from instance' do
		let(:model) { Model.new(:id) }

		let(:form_class) do
			Class.new(described_class) do
				field :id, Array, of: Integer

				private

				def instance_respond_to?(name)
					@instance.first&.respond_to?(name)
				end

				def instance_public_send(name)
					@instance.map { |instance| instance.public_send(name) }
				end
			end
		end

		describe '`:id` field' do
			subject { form.id }

			let(:correct_id) { [2, 5, 6] }

			context 'when initialized from Array of Integer' do
				let(:params) { { id: correct_id } }

				it { is_expected.to eq correct_id }
			end

			context 'when initialized from Array of instances' do
				let(:params) { correct_id.map { |id| model.new(id: id) } }

				it { is_expected.to eq correct_id }
			end
		end
	end
end
