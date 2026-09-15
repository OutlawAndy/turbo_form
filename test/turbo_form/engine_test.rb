require "test_helper"

class TurboForm::EngineTest < ActiveSupport::TestCase
  # The pin is keyed `controllers/..._controller` so that the stock
  # `eagerLoadControllersFrom("controllers", application)` in a Rails app finds
  # it and registers it as `turbo-form` with no host configuration at all.
  # Asserting on the *rendered* map, not just the drawn pin: importmap-rails
  # drops any pin whose asset it can't resolve, with nothing louder than a
  # warning in the log.
  test "pins the Stimulus controller into the host's importmap" do
    imports = JSON.parse(Rails.application.importmap.to_json(resolver: ActionController::Base.helpers))["imports"]

    assert_match %r{\A/assets/turbo_form-\h+\.js\z}, imports["controllers/turbo_form_controller"]
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
