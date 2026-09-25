require "turbo-rails"
require "turbo_form/form_helper"
require "turbo_form/form_builder"
require "turbo_form/reload"

module TurboForm
  class Engine < ::Rails::Engine
    # importmap-rails reads config.importmap.paths exactly once, in its own
    # `importmap` initializer, and draws the host's pins last -- so appending
    # here both registers ours and leaves the host able to override them.
    # The guard keeps esbuild/vite/bun hosts booting; a `before:` naming an
    # initializer that doesn't exist is itself harmless.
    initializer "turbo_form.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/turbo_form_importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
    end

    # Propshaft puts every engine's app/assets/* on the load path by itself.
    # Sprockets additionally wants the asset named, or the pin above silently
    # resolves to nothing.
    initializer "turbo_form.assets" do |app|
      next unless app.config.respond_to?(:assets)

      app.config.assets.precompile << "turbo_form.js"
    end

    # Minitest's system tests descend from ActionDispatch::SystemTestCase, so
    # the load hook reaches them. RSpec's don't -- RSpec::Rails::SystemExampleGroup
    # assembles itself from Action Dispatch's parts instead of inheriting the
    # case -- so they need telling separately, once RSpec is loaded but before
    # any example group has been defined.
    initializer "turbo_form.system_test_helper" do
      ActiveSupport.on_load(:action_dispatch_system_test_case) do
        require "turbo_form/system_test_helper"

        include TurboForm::SystemTestHelper
      end
    end

    config.after_initialize do
      next unless defined?(RSpec.configure)

      require "turbo_form/system_test_helper"

      RSpec.configure do |config|
        config.include TurboForm::SystemTestHelper, type: :system
      end
    end

    initializer "turbo_form.reload" do |app|
      app.middleware.use TurboForm::Reload::Middleware
    end

    # Deliberately eager rather than `ActiveSupport.on_load(:action_view)`: that
    # hook doesn't fire until Action View is first loaded, which in an app that
    # isn't eager loading is partway through rendering the first view -- late
    # enough that the first form on the first request can miss the patch.
    initializer "turbo_form.form_helpers" do
      require "action_view"

      ActionView::Helpers::FormHelper.prepend(TurboForm::FormHelper)
      ActionView::Helpers::FormBuilder.prepend(TurboForm::FormBuilder)
    end
  end
end
