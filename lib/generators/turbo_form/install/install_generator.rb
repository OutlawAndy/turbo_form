require "rails/generators"

module TurboForm
  module Generators
    # Every app gets the shadow action, the route concern its resources opt
    # into and an import of the script. On importmap-rails the engine pins the
    # script itself; bundled apps get the npm package to import instead.
    class InstallGenerator < Rails::Generators::Base
      LOCKFILES = {
        "yarn.lock" => "yarn add", "pnpm-lock.yaml" => "pnpm add",
        "bun.lock" => "bun add", "bun.lockb" => "bun add"
      }.freeze

      ENTRYPOINT = "app/javascript/application.js"

      def install
        include_controller
        declare_route_concern
        install_package unless importmap?
        import_script
      end

      private
        def include_controller
          inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include TurboForm::Controller\n"
        end

        # Declared once, drawn on no resource: which forms are dynamic is the
        # app's call, one `concerns: :turbo_form` at a time.
        def declare_route_concern
          route "concern :turbo_form, TurboForm::Routes"
        end

        def importmap? = Rails.root.join("config/importmap.rb").exist?

        def install_package
          run "#{package_manager} #{package}"
        end

        def import_script
          import = %(import "#{importmap? ? "turbo_form" : "@rolemodel/turbo-form"}"\n)
          return say("Add #{import.strip} to your JavaScript entrypoint.") unless Rails.root.join(ENTRYPOINT).exist?

          append_to_file ENTRYPOINT, import
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
