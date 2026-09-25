require "test_helper"
require "rails/generators/test_case"
require "generators/turbo_form/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  COMMANDS = []

  # Whatever the generator would shell out to, remembered instead of run: the
  # suite has an opinion about which package manager is chosen, none about
  # whether yarn works.
  module RecordsCommands
    def run(command, *) = COMMANDS << command
  end
  TurboForm::Generators::InstallGenerator.prepend(RecordsCommands)

  tests TurboForm::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator", __dir__)

  setup { COMMANDS.clear }
  setup { @original_root = Rails.application.config.root }
  teardown { Rails.application.config.root = @original_root }

  test "imports the package into a bundled app's entrypoint" do
    in_app do
      run_generator

      assert_file "app/javascript/application.js", %(import "@rolemodel/turbo-form"\n)
    end
  end

  test "imports the engine's pin into an importmap app, and installs no package" do
    in_app do
      File.write(File.join(destination_root, "config/importmap.rb"), "")
      run_generator

      assert_file "app/javascript/application.js", %(import "turbo_form"\n)
      assert_empty COMMANDS
    end
  end

  test "asks for the import when the app keeps its entrypoint elsewhere" do
    in_app do
      File.delete(File.join(destination_root, "app/javascript/application.js"))

      assert_match %(Add import "@rolemodel/turbo-form" to your JavaScript entrypoint.), run_generator
    end
  end

  test "mixes the shadow action into ApplicationController and declares the route concern" do
    in_app do
      run_generator

      assert_file "app/controllers/application_controller.rb", /class ApplicationController < ActionController::Base\n  include TurboForm::Controller\n/
      assert_file "config/routes.rb", /draw do\n  concern :turbo_form, TurboForm::Routes\n/
    end
  end

  test "running it twice adds each line once" do
    in_app do
      2.times { run_generator }

      assert_file("app/controllers/application_controller.rb") { |controller| assert_equal 1, controller.scan("include TurboForm::Controller").size }
      assert_file("config/routes.rb") { |routes| assert_equal 1, routes.scan("concern :turbo_form").size }
      assert_file("app/javascript/application.js") { |js| assert_equal 1, js.scan("import").size }
    end
  end

  test "installs the package with the manager the app already keeps a lockfile for" do
    {
      "yarn.lock" => "yarn add", "pnpm-lock.yaml" => "pnpm add", "bun.lock" => "bun add", nil => "npm install"
    }.each do |lockfile, manager|
      in_app do
        FileUtils.touch File.join(destination_root, lockfile) if lockfile
        run_generator

        assert_equal [ "#{manager} @rolemodel/turbo-form@#{TurboForm::VERSION}" ], COMMANDS
      end
    end
  end

  private
    # The generator reads the app it is installing into off `Rails.root`, and
    # the app under test is the destination, not the dummy.
    def in_app
      prepare_destination
      COMMANDS.clear
      FileUtils.mkdir_p File.join(destination_root, "config")
      FileUtils.mkdir_p File.join(destination_root, "app/javascript")
      File.write(File.join(destination_root, "app/javascript/application.js"), "")
      FileUtils.mkdir_p File.join(destination_root, "app/controllers")
      File.write(File.join(destination_root, "app/controllers/application_controller.rb"), "class ApplicationController < ActionController::Base\nend\n")
      File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")

      Rails.application.config.root = destination_root
      yield
    end
end
