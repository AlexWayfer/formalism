# Formalism

[![Build Status](https://api.cirrus-ci.com/github/AlexWayfer/formalism.svg)](https://cirrus-ci.com/github/AlexWayfer/formalism)

Ruby gem for forms with validations and nesting.

## Why

I need for service-like objects.

I've explored these projects:

*   [Reform](https://github.com/trailblazer/reform)
*   [Mutations](https://github.com/cypriss/mutations)
*   [Interactor](https://github.com/collectiveidea/interactor)
*   [dry-rb](https://github.com/dry-rb)

But nothing of them supports all features I need for:

*   nesting (into unlimited levels) of themselves;
*   simple syntax;
*   custom validations and coercions;
*   unified output.

So, I've tried to combine these all into one library and got Formalism.

### Why here are forms and what about service objects?

I've discovered that form object, only with validations,
are useless without service objects. So, I've combined them:
service objects include validations.

### If these are service objects, why they called forms?

Because if we're combining them — it's more like forms with logic inside for me
than service objects built-in forms. Even in HTML we're writing `<form>`.
So, Formalism can accept all data from any-difficult `<form>` and process it,
also with nested forms (for example, if you have some request form
with contact data and want to pass contacts into something like user form).

### And if I need for simple service object without validation?

You can use `Formalism::Action`, a parent of `Formalism::Form`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'formalism'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install formalism
```

## Usage

### Basic example

```ruby
class FindArtistForm < Formalism::Form
  field :name

  private

  def validate
    if name.to_s.empty?
      errors.add 'Name is not provided'
    end
  end

  def execute
    Artist.first(fields_and_nested_forms)
  end
end

class CreateAlbumForm < Formalism::Form
  field :name, String
  fiels :tags, Array, of: String
  nested :artist, FindArtistForm

  private

  def validate
    if name.to_s.empty?
      errors.add 'Name is not provided'
    end
  end

  def execute
    Album.create(fields_and_nested_forms)
  end
end

form = CreateAlbumForm.new(
  name: 'Hits', tags: %w[Indie Rock Hits], artist: { name: 'Alex' }
)
form.run
```

### Running

Usually you need to initialize a form and execute `#run` method.
Internally, it runs `#valid?` (public) and `#execute` (private) methods.
`#valid?` runs `#validate` (private) of a form itself and nested forms.
`#run` can be redefined for database transaction, for example.

Also you can call `.run` with arguments for `#initialize`,
it's the alias for `#initialize` + `#run`.

#### Form outcome

Any call of `run` returns `Form::Outcome` instance which has `#success?`,
`#result` and `#errors` methods. Result is a result of `#execute` method.
Be careful: calling `#result` for failed outcome will raise `ValidationError`.

### Field type

Field receives type as the second argument.
It's not required.
It can be a constant, String or Symbol.
If specified — there is a coercion to specified type,
if not — data remains unchanged.

Nested forms — their class, as constant.
Type or `:initialize` block is required.

Formalism also supports `Array` type with the optional `:of` option
(type of elements).
Coercion will be applied to a data itself and to its elements.

#### Coercion

There is built-in coercion into some types, if you try to coerce
to undefined type — you'll get `Formalism::Form::NoCoercionError`.

You can define a coercion to some type via definition of such class:

```ruby
# frozen_string_literal: true

module Formalism
  class Form < Action
    class Coercion
      ## Class for coercion to String
      class String < Base
        private

        def execute
          @value&.to_s
        end
      end
    end
  end
end
```

### Default value

`field` and `nested` accepts `:default` option.
It can be any value, if it's an instance of `Proc` — it'll be executed
in the form instance scope.

### Different keys

`field` supports `:key` option (Symbol) to receive data by a different key,
not as a field name.

### Custom initialization of nested forms

By default, nested forms initialized with data by key as their name
in parent data. So, if a parent receive `{ foo: 1, bar: { baz: 2 } }`,
it's nested form `:bar` will receive `{ baz: 2 }`.

If you want to prevent initialization at all, or pass custom arguments —
you should use `:initialize` option which accepts a proc
with a form class argument.

If you want to just refine incoming data (add or remove) — you should define
`#params_for_nested_*` private method, where `*` is a nested form name.
You can use `super` inside.

### Order of filling with data

Fields and nested forms are filling in order of their definition.
But sometimes you want to change this order, for example,
if you have a nested forms in ancestors which depends on data in children forms.
For such cases you can use `:depends_on` option, which accepts fields
and nested forms names as Symbol or Array of symbols. They will be filled
(and initialized) before dependent.

### Merging into final data

There is `Form#fields_and_nested_forms` as final data
(after coercion, defaults, etc). But you may want to not include some fields
or nested forms into this data. You can do it via `:merge` option,
which can be `true`, `false` or `Proc` (executed in form's instance scope).

For example:

```ruby
field :bar, merge: true
nested :only_valid, nested_form_class, merge: ->(form) { form.valid? }
```

### Runnable

You can disable `#valid?` and `#run` of forms (including nested ones)
by setting `form.runnable = false`.
It can be helpful for some cases, for example, with policies (permissions):

```ruby
def initialize_nested_form(name, options)
  return unless (form = super)

  form.runnable = allowed_to_change?(name)
  form
end
```

### Inheritance

Any `class ChildForm < ParentForm` will have all fields and nested forms
from `ParentForm`.

#### Removing (inherited) field

But you're able to remove (usually inherited) fields by:

```ruby
class ChildForm < ParentForm
  remove_field :field_from_parent
end
```

#### Modules

You can define modules and use them later like this:

```ruby
module CommonFields
  include Formalism::Form::Fields

  field :base_field
  nested :base_nested
end

class SomeForm < Formalism::Form
  include CommonFields

  field :another_field
end
```

### Convert to params

You can convert a Form back to (processed) params, for example, for view render:

```ruby
form = CreateAlbumForm.new(
  name: 'Hits', tags: %w[Indie Rock Hits], artist: { name: 'Alex' }
)

form.to_params
# {
#   name: 'Hits',
#   tags: %w[Indie Rock Hits],
#   artist: { name: 'Alex' }
# }
```

### Actions

For actions without fields, nesting and validation you can use
`Formalism::Action` (the parent of `Formalism::Form`).

## Development

After checking out the repo, run `bundle install` to install dependencies.
Then, run `bundle exec rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag
for the version, push git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/AlexWayfer/formalism).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
