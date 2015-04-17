# Monatomic

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/monatomic`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'monatomic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monatomic

## Usage

TODO: Write usage instructions here

### Access Control

There are two types of ACL, based on a model or based on a field.
The later is more powerful and slower than the former.
A user must get **both two permits** to read or write a record (with according fields).

There are three kinds of permission, readable, writable and deletable.

A field-based ACL could be like this

```ruby
field :email, readable: :admin,  writable: :admin
field :password, readable: false, writable: -> { everyone: -> (user) { id == user.id }
```

A record-based (or model-based) ACL could be like this

```ruby
set :readable, true
# which is equal to
set :readable, :everyone

set :readable, [:role1, :role2]

set :writable, -> (user) { user.is(:admin) or created_at > 1.day.ago }
# which is equal to
set :writable, [:admin, -> { created_at > 1.day.ago }]

set :deletable, -> (user) { user.is(:admin) }
```

However, for some performance reason, common block is not supported in readable, i.e., this is not allowed.

```ruby
set :readable, -> (user) { user.is(:admin) or author.id == id or created_at > 1.day.ago }
```

In order to provide such functionality, you can use

```ruby
set :readable, -> (user) { if user.is(:admin) then true else { id: user.id, :created_at.gt => 1.day.ago } }
# or
set :readable, [:admin, -> (user) { { id: user.id, :created_at.gt => 1.day.ago } }]
```

where `{ id: user.id, :created_at.gt => 1.day.ago }` is a [mongoid selector](http://mongoid.org/en/origin/docs/selection.html#symbol).

"Deletable" is only controlled by record-based ACL, of course.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/liudangyi/monatomic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
