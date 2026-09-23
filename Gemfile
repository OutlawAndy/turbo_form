source "https://rubygems.org"

# Specify your gem's dependencies in turbo_form.gemspec.
gemspec

gem "propshaft"
gem "puma"

# The dummy app models its resource with plain Active Model rather than Active
# Record: it keeps the suite fast and proves the engine isn't coupled to the ORM.
gem "activemodel"

# Only the endpoint's rollback of writes is Active Record's business, so only
# its test loads it -- the dummy app still boots without.
gem "activerecord", require: false
gem "sqlite3", require: false

# Exercised by the engine's importmap integration test.
gem "importmap-rails"

# The install generator leans on Stimulus' own manifest to register its
# controller, and the generator test proves that a regenerated manifest keeps it.
gem "stimulus-rails"

# ActionDispatch::SystemTestCase won't load without it, and the system test
# helper is Capybara's to begin with.
gem "capybara"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
gem "debug", ">= 1.0.0"
