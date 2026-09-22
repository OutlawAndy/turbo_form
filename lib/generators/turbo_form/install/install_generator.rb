require "rails/generators"

module TurboForm
  module Generators
    # There is nothing to install on importmap-rails: the engine pins its own
    # Stimulus controller and a stock `app/javascript/controllers/index.js`
    # registers it. Bundled apps get no such sweep, so this hands them the two
    # things they'd otherwise write by hand -- the package and the registration.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      LOCKFILES = {
        "yarn.lock" => "yarn add", "pnpm-lock.yaml" => "pnpm add",
        "bun.lock" => "bun add", "bun.lockb" => "bun add"
      }.freeze

      def install
        if importmap?
          say "turbo_form registers its own Stimulus controller on importmap-rails. Nothing to install."
          return
        end

        install_package
        register_controller
        update_stimulus_manifest
      end

      private
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
