require_relative "boot"

require "rails"
# Deliberately minimal: turbo_form needs nothing beyond Active Model, Action
# Controller and Action View, and booting without Active Record keeps that honest.
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    config.autoload_lib(ignore: %w[assets tasks])
  end
end
