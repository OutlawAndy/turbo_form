require "test_helper"
require "rails/generators/test_case"
require "generators/turbo_form/install/install_generator"
require "stimulus/manifest"

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

  test "registers the controller by filename, where the stimulus manifest will find it" do
    in_app do
      run_generator

      assert_file "app/javascript/controllers/turbo_form_controller.js" do |js|
        assert_match %r{import TurboFormController from "@rolemodel/turbo-form"}, js
        assert_match "export default TurboFormController", js
      end
    end
  end

  # The whole reason the registration lives in its own file: index.js is
  # rewritten from this manifest every time `rails generate stimulus` runs, so
  # anything appended to it by hand would not survive. Asked of the real
  # Stimulus, with the real filename.
  test "the stimulus manifest picks the controller back up when it is regenerated" do
    in_app do
      run_generator

      manifest = Stimulus::Manifest.generate_from(Rails.root.join("app/javascript/controllers")).join
      assert_match %r{import TurboFormController from "\./turbo_form_controller"}, manifest
      assert_match %r{application\.register\("turbo-form", TurboFormController\)}, manifest
    end
  end

  test "does nothing to an importmap app" do
    in_app do
      File.write(File.join(destination_root, "config/importmap.rb"), "")

      assert_no_match "turbo_form_controller.js", run_generator
      assert_no_file "app/javascript/controllers/turbo_form_controller.js"
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
      FileUtils.mkdir_p File.join(destination_root, "app/javascript/controllers")
      File.write(File.join(destination_root, "app/javascript/controllers/application.js"), "")

      Rails.application.config.root = destination_root
      yield
    end
end
