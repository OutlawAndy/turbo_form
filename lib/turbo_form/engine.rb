require "turbo-rails"
require "turbo_form/form_helper"
require "turbo_form/form_builder"
require "turbo_form/signature"

module TurboForm
  # Deliberately *not* `isolate_namespace`: the template this engine renders
  # belongs to the host, and isolating would point its route helpers at this
  # engine's own (empty) route set -- so `widgets_path` in a host's
  # dynamic_form template would raise.
  class Engine < ::Rails::Engine
    config.turbo_form = ActiveSupport::OrderedOptions.new

    initializer "turbo_form.assets" do |app|
      if Rails.application.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
        # app.config.assets.precompile += %w[app/assets/config/manifest.js]
      end
    end

    # initializer "turbo_form.importmap", before: "importmap" do |app|
    #   # https://github.com/rails/importmap-rails#composing-import-maps
    #   app.config.importmap.paths << root.join("config/importmap.rb")

    #   # https://github.com/rails/importmap-rails#sweeping-the-cache-in-development-and-test
    #   app.config.importmap.cache_sweepers << root.join("app/javascript")
    # end

    initializer "turbo_form.initialize" do |app|
      app.config.to_prepare do
        ActionView::Helpers::FormHelper.prepend(TurboForm::FormHelper)
        ActionView::Helpers::FormBuilder.prepend(TurboForm::FormBuilder)
      end
    end
  end
end
