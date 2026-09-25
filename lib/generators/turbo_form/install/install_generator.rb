require "rails/generators"

module TurboForm
  module Generators
    # Every app gets the shadow action and the route concern its resources opt
    # into. The JavaScript is only for bundled apps: on importmap-rails the
    # engine pins its own Stimulus controller and a stock
    # `app/javascript/controllers/index.js` registers it. Bundled apps get no
    # such sweep, so this hands them the package and the registration.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      LOCKFILES = {
        "yarn.lock" => "yarn add", "pnpm-lock.yaml" => "pnpm add",
        "bun.lock" => "bun add", "bun.lockb" => "bun add"
      }.freeze

      def install
        include_controller
        declare_route_concern

        if importmap?
          say "turbo_form registers its own Stimulus controller on importmap-rails. No JavaScript to install."
          return
        end

        install_package
        register_controller
        update_stimulus_manifest
      end

      private
        def include_controller
          inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include TurboForm::Controller\n"
        end

        # Declared once, drawn on no resource: which forms are dynamic is the
        # app's call, one `concerns: :dynamic_form` at a time.
        def declare_route_concern
          route "concern :dynamic_form, TurboForm::Routes"
        end

        def importmap? = Rails.root.join("config/importmap.rb").exist?

        def install_package
          run "#{package_manager} #{package}"
        end

        # Named for the controller it is, rather than imported into `index.js`:
        # that file is rewritten wholesale every time `rails generate stimulus`
        # runs, and would take a registration appended to it down with it. The
        # manifest is generated from this directory instead, so a file named
        # this way is picked back up every time and registered as `turbo-form`.
        def register_controller
          copy_file "turbo_form_controller.js", "app/javascript/controllers/turbo_form_controller.js"
        end

        # Left to Stimulus' own task rather than written here, the way the
        # `stimulus` generator does it: the task is what the app already trusts
        # to regenerate this file, and its internals have moved between releases.
        def update_stimulus_manifest
          return unless Rails.root.join("app/javascript/controllers/index.js").exist?

          rails_command "stimulus:manifest:update"
        end

        def package = "@rolemodel/turbo-form@#{TurboForm::VERSION}"

        # Matched to the lockfile that is already there, so the generator doesn't
        # introduce a second package manager to an app that settled on one.
        def package_manager
          LOCKFILES.find { |lockfile, _| Rails.root.join(lockfile).exist? }&.last || "npm install"
        end
    end
  end
end
