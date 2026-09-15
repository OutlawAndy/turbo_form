require 'turbo_form/form_helper'
require 'turbo_form/form_builder'

module TurboForm
  class Engine < ::Rails::Engine
    isolate_namespace TurboForm

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
