require "test_helper"

class TurboForm::EngineTest < ActiveSupport::TestCase
  # Asserting on the *rendered* map, not just the drawn pin: importmap-rails
  # drops any pin whose asset it can't resolve, with nothing louder than a
  # warning in the log.
  test "pins the script into the host's importmap" do
    imports = JSON.parse(Rails.application.importmap.to_json(resolver: ActionController::Base.helpers))["imports"]

    assert_match %r{\A/assets/turbo_form-\h+\.js\z}, imports["turbo_form"]
  end

  test "includes the system test helper in Minitest's system tests" do
    require "action_dispatch/system_test_case"

    assert_includes ActionDispatch::SystemTestCase.ancestors, TurboForm::SystemTestHelper
  end

  # RSpec's system specs don't descend from ActionDispatch::SystemTestCase, so
  # that hook never reaches them and the engine has to hand RSpec the helper
  # itself. In a subprocess because `after_initialize` has already run -- with
  # no RSpec in sight -- by the time this suite starts.
  test "hands the helper to RSpec's system specs" do
    script = <<~'RUBY'
      module RSpec
        REGISTERED = []

        def self.configure = yield(self)
        def self.include(mod, **filters) = REGISTERED << [mod, filters]
      end

      require "rails"
      require "action_controller/railtie"
      require "action_view/railtie"
      require "turbo_form"

      class RSpecApp < Rails::Application
        config.eager_load = false
        config.secret_key_base = "test"
      end
      RSpecApp.initialize!

      expected = [[TurboForm::SystemTestHelper, { type: :system }]]
      abort "registered #{RSpec::REGISTERED.inspect}" unless RSpec::REGISTERED == expected
    RUBY

    _out, error, status = Open3.capture3(RbConfig.ruby, "-e", script, chdir: TurboForm::Engine.root.to_s)

    assert status.success?, error
  end

  test "boots an app that has no importmap-rails" do
    script = <<~RUBY
      require "rails"
      require "action_controller/railtie"
      require "action_view/railtie"
      require "turbo_form"
      abort "importmap-rails was loaded; this proves nothing" if defined?(Importmap)

      class BundlerApp < Rails::Application
        config.eager_load = false
        config.secret_key_base = "test"
      end
      BundlerApp.initialize!
    RUBY

    _out, error, status = Open3.capture3(RbConfig.ruby, "-e", script, chdir: TurboForm::Engine.root.to_s)

    assert status.success?, error
  end
end
