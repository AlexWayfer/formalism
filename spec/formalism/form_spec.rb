# frozen_string_literal: true

describe Formalism::Form do
	before do
		stub_const('YEAR_RANGE', 0..Time.now.year)

		stub_const(
			'Model', Class.new(Struct) do
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

				def initialize(**columns)
					columns.each do |column, value|
						public_send "#{column}=", value
					end
				end

				def id
					@id ||= all.last&.id.to_i + 1
				end

				def id=(_value)
					raise ArgumentError, 'id is a restricted primary key'
				end

				def save
					all = self.class.all
					all.delete_if { |record| record.id == id }
					all.push self
					self
				end
			end
		)

		stub_const(
			'Album', Model.new(:title, :year, :artist, :tag, :label, :genre)
		)

		stub_const(
			'AlbumForm', Class.new(described_class) do
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
					@album = Album.create(fields_and_nested_forms)
				end
			end
		)
	end

	describe '.field' do
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
					@entity = Model.new(:foo, :bar).create(fields_and_nested_forms)
				end
			end
		end

		let(:form) { form_class.new(params) }

		let(:not_coerced_time) { '2018-05-03 14:02:21' }

		let(:not_coerced_params) do
			{
				foo: '1', bar: '2', baz: 3, count: '-0123', price: '+00456.789',
				status: 'activated', tags: 1..3, ids: ['04', 5, '6'],
				release_date: '1.1.2001'
			}
		end

		let(:coerced_time) { Time.new(2018, 5, 3, 14, 2, 21) }

		let(:coerced_params) do
			{
				foo: '1', bar: 2, baz: '3', count: -123, price: 456.789,
				status: :activated, tags: [1, 2, 3], ids: [4, 5, 6],
				release_date: Date.new(2001, 1, 1)
			}
		end

		subject { form.fields }

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

		describe 'coersion' do
			context 'params must be coerced' do
				let(:params) { not_coerced_params.merge(qux: 4) }

				it { is_expected.to eq coerced_params }

				it 'returns coerced values from getters' do
					coerced_params.each do |name, value|
						expect(form.public_send(name)).to eq(value)
					end
				end
			end

			context 'params must not be coerced' do
				let(:params) { coerced_params.merge(qux: 4) }

				it { is_expected.to eq coerced_params }
			end

			describe 'coercion to Time' do
				let(:coerced_time_params) { { created_at: coerced_time } }

				context 'value is String' do
					let(:params) { { created_at: not_coerced_time } }

					it { is_expected.to eq(coerced_time_params) }
				end

				context 'value is Time' do
					let(:params) { coerced_time_params }

					it { is_expected.to eq(coerced_time_params) }
				end

				context 'value is nil' do
					let(:params) { { created_at: nil } }

					it { is_expected.to eq(created_at: nil) }
				end
			end

			describe 'coercion to boolean' do
				context "value is 'true'" do
					let(:params) { { enabled: 'true' } }

					it { is_expected.to eq(enabled: true) }
				end

				context 'value is true' do
					let(:params) { { enabled: true } }

					it { is_expected.to eq(enabled: true) }
				end

				context 'value is false' do
					let(:params) { { enabled: false } }

					it { is_expected.to eq(enabled: false) }
				end

				context 'value is nil' do
					let(:params) { { enabled: nil } }

					it { is_expected.to eq(enabled: false) }
				end

				context "value is 'false'" do
					let(:params) { { enabled: 'false' } }

					it { is_expected.to eq(enabled: false) }
				end
			end

			describe 'error if there is no defined coercion to the required type' do
				shared_examples 'raise error' do
					it do
						expect { subject }.to raise_error(
							Formalism::NoCoercionError, 'Formalism has no coercion to Module'
						)
					end
				end

				context 'regular type of field' do
					subject do
						Class.new(described_class) do
							field :foo
							field :bar, Module
						end
					end

					it_behaves_like 'raise error'
				end

				context 'type of Array' do
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
					field :created_at, Time, default: -> { default_created_at }
					field :updated_at, Time, default: -> { created_at }
					field :count, :integer, default: 0
					field :price, Float, default: 2.5
					field :enabled, :boolean, default: false
					field :status, Symbol, default: :all
					field :release_date, Date, default: -> { Date.new(2002, 1, 1) }
					field :tags, Array, default: [:world]
					field :ids, Array, of: Integer, default: [7, 8]

					def initialize(params, set_count: false)
						self.count = 2 if set_count

						super params
					end
				end
			end

			let(:form) { form_class.new(params, set_count: set_count) }
			let(:set_count) { false }

			context 'params is filled' do
				let(:params) do
					not_coerced_params.merge(
						name: 'Alex',
						created_at: not_coerced_time,
						updated_at: '2018-05-07 21:49',
						enabled: 'true',
						qux: 4
					)
				end

				it do
					is_expected.to eq coerced_params.merge(
						name: 'Alex',
						created_at: coerced_time,
						updated_at: Time.new(2018, 5, 7, 21, 49),
						enabled: true
					)
				end
			end

			context 'params is empty' do
				let(:params) { {} }

				it do
					is_expected.to eq(
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
					)
				end
			end

			context 'field set in initializer before super' do
				let(:set_count) { true }

				subject { super()[:count] }

				context 'params is filled' do
					let(:params) { not_coerced_params }

					it { is_expected.to eq coerced_params[:count] }
				end

				context 'params is empty' do
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
				end
			end

			let(:form_class) do
				Class.new(parent_form_class) do
					field :bar
				end
			end

			let(:params) { { foo: 1, bar: '2', baz: Time.now } }

			it { is_expected.to eq(foo: 1, bar: '2') }
		end

		describe ':merge option' do
			subject { form.run }

			let(:params) { { id: 2 } }

			it { expect { subject }.not_to raise_error }
		end
	end

	subject(:album_form) { AlbumForm.new(params) }

	let(:correct_album_params) { { title: 'Foo', year: 2018 } }

	describe '#fields' do
		subject { album_form.fields }

		context 'not enough params' do
			let(:params) { { title: 'Foo' } }

			it { is_expected.to eq(title: 'Foo') }
		end

		context 'enough params' do
			let(:params) { correct_album_params }

			it { is_expected.to eq(correct_album_params) }
		end

		context 'more than enough params' do
			let(:params) { correct_album_params.merge(artist: 'Bar') }

			it { is_expected.to eq(correct_album_params) }
		end
	end

	describe '#valid?' do
		subject { album_form.valid? }

		context 'correct params' do
			let(:params) { correct_album_params }

			it { is_expected.to be true }
		end

		context 'incorrect params' do
			let(:params) { { year: 3018 } }

			it { is_expected.to be false }
		end
	end

	describe '#run' do
		subject { album_form.run }

		describe '#success?' do
			subject { super().success? }

			context 'correct params' do
				let(:params) { correct_album_params }

				after do
					expect(Album.all).to eq([Album.new(params)])
				end

				it { is_expected.to be true }
			end

			context 'incorrect params' do
				let(:params) { { year: 3018 } }

				after do
					expect(Album.all).to be_empty
				end

				it { is_expected.to be false }
			end
		end

		describe '#errors' do
			subject { super().errors }

			context 'correct params' do
				let(:params) { correct_album_params }

				after do
					expect(Album.all).to eq([Album.new(params)])
				end

				it { is_expected.to be_empty }
			end

			context 'incorrect params' do
				let(:params) { { year: 3018 } }

				after do
					expect(Album.all).to be_empty
				end

				it do
					is_expected.to eq [
						'Album title is not present',
						"Album year is not in #{YEAR_RANGE}"
					].to_set
				end
			end
		end

		describe '#result' do
			subject { super().result }

			context 'correct params' do
				let(:params) { correct_album_params }

				after do
					expect(Album.all).to eq([Album.new(params)])
				end

				it { is_expected.to eq Album.new(params) }
			end

			context 'incorrect params' do
				let(:params) { { year: 3018 } }

				after do
					expect(Album.all).to be_empty
				end

				it { is_expected.to be_nil }
			end
		end
	end

	describe '.nested' do
		before do
			stub_const(
				'Artist', Model.new(:name)
			)

			stub_const(
				'Tag', Model.new(:name)
			)

			stub_const(
				'Label', Model.new(:name)
			)

			stub_const(
				'ArtistForm', Class.new(described_class) do
					attr_reader :artist

					field :name

					private

					def validate
						return unless name.to_s.empty?

						errors.add('Artist name is not present')
					end

					def execute
						@artist = Artist.find_or_create(fields_and_nested_forms)
					end
				end
			)

			stub_const(
				'TagForm', Class.new(described_class) do
					field :name, String

					attr_reader :tag

					private

					def execute
						@tag = Tag.find_or_create(fields_and_nested_forms)
					end
				end
			)

			stub_const(
				'LabelForm', Class.new(described_class) do
					attr_reader :label

					def initialize(name)
						@name = name
					end

					private

					def execute
						@label = Label.find_or_create(name: @name)
					end
				end
			)

			stub_const(
				'CompositorForm', Class.new(described_class) do
					attr_reader :compositor

					field :name

					private

					def validate
						return unless name.to_s.empty?

						errors.add('Compositor name is not present')
					end

					def execute
						@compositor = Compositor.find_or_create(fields_and_nested_forms)
					end
				end
			)

			stub_const(
				'AlbumWithNestedForm', Class.new(AlbumForm) do
					nested :artist, ArtistForm

					nested :tag, TagForm, default: -> { default_tag }

					nested :label, LabelForm,
						initialize: ->(form) { form.new(params[:label_name]) }

					field :genre, default: -> { label }

					nested :compositor, initialize: (
						proc do
							(artist_form.valid? ? ArtistForm : CompositorForm)
								.new(params[artist_form.valid? ? :artist : :compositor])
						end
					), merge: false

					nested :update_something, initialize: ->(_form) { nil }

					nested :hashtag, TagForm, instance_variable: :tag, merge: false

					private

					def execute
						artist_form.run
						tag_form.run
						label_form.run
						super
					end

					def default_tag
						Tag.new(name: 'default')
					end
				end
			)
		end

		let(:album_with_nested_form) { AlbumWithNestedForm.new(params) }

		context 'without form and :initialize parameters' do
			subject do
				lambda do
					AlbumWithNestedForm.nested :incorrect_form
				end
			end

			it do
				is_expected.to raise_error(
					ArgumentError,
					'Neither form class nor initialize block is not present'
				)
			end
		end

		describe '#valid?' do
			subject { album_with_nested_form.valid? }

			context 'correct params' do
				let(:params) { correct_album_params.merge(artist: { name: 'Bar' }) }

				it { is_expected.to be true }
			end

			context 'incorrect params' do
				let(:params) { correct_album_params.merge(artist: { name: '' }) }

				it { is_expected.to be false }
			end
		end

		describe '#run' do
			subject { album_with_nested_form.run }

			describe '#success?' do
				subject { super().success? }

				context 'correct params' do
					let(:params) do
						correct_album_params.merge(
							artist: { name: 'Bar' }, tag: { name: 'Blues' }, label_name: 'RAM'
						)
					end

					after do
						artist = Artist.new(name: 'Bar')
						tag = Tag.new(name: 'Blues')
						label = Label.new(name: 'RAM')

						expect(Album.all).to eq([
							Album.new(
								correct_album_params.merge(
									artist: artist, tag: tag, label: label
								)
							)
						])
						expect(Artist.all).to eq([artist])
						expect(Tag.all).to eq([tag])
						expect(Label.all).to eq([label])
					end

					it { is_expected.to be true }
				end

				context 'incorrect params' do
					let(:params) { { title: '', year: 2018, artist: { name: '' } } }

					after do
						expect(Album.all).to be_empty
						expect(Artist.all).to be_empty
						expect(Label.all).to be_empty
						expect(album_with_nested_form.tag).to eq(Tag.new(name: 'default'))
					end

					it { is_expected.to be false }
				end
			end

			describe '#errors' do
				subject { super().errors }

				context 'correct params' do
					let(:params) do
						correct_album_params.merge(
							artist: { name: 'Bar' }, tag: { name: 'Blues' }, label_name: 'RAM'
						)
					end

					after do
						artist = Artist.new(name: 'Bar')
						tag = Tag.new(name: 'Blues')
						label = Label.new(name: 'RAM')

						expect(Album.all).to eq([
							Album.new(
								correct_album_params.merge(
									artist: artist, tag: tag, label: label
								)
							)
						])
						expect(Artist.all).to eq([artist])
						expect(Tag.all).to eq([tag])
						expect(Label.all).to eq([label])
					end

					it { is_expected.to be_empty }
				end

				context 'incorrect params' do
					let(:params) { { title: '', year: 2018, artist: { name: '' } } }

					after do
						expect(Album.all).to be_empty
						expect(Artist.all).to be_empty
						expect(Label.all).to be_empty
						expect(album_with_nested_form.tag).to eq(Tag.new(name: 'default'))
					end

					it do
						is_expected.to eq [
							'Album title is not present', 'Artist name is not present',
							'Compositor name is not present'
						].to_set
					end
				end
			end
		end
	end
end
