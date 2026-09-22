require "test_helper"
require "rails/generators/test_case"
require "generators/turbo_form/install/install_generator"
require "stimulus/manifest"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests TurboForm::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator", __dir__)

  setup :prepare_destination
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
      "yarn.lock" => "yarn add", "pnpm-lock.yaml" => "pnpm add", "bun.lock" => "bun add"
    }.each do |lockfile, manager|
      in_app do
        FileUtils.touch File.join(destination_root, lockfile)

        assert_equal "#{manager} @rolemodel/turbo-form@#{TurboForm::VERSION}",
          "#{generator.send(:package_manager)} #{generator.send(:package)}"
      end
    end
  end

  test "installs with npm when no lockfile names anything else" do
    in_app { assert_equal "npm install", generator.send(:package_manager) }
  end

  private
    # The generator reads the app it is installing into off `Rails.root`, and
    # the app under test is the destination, not the dummy. `package.json` is
    # left out of it on purpose: without one the generator skips the install,
    # so the suite never shells out to a package manager.
    def in_app
      prepare_destination
      FileUtils.mkdir_p File.join(destination_root, "config")
      FileUtils.mkdir_p File.join(destination_root, "app/javascript/controllers")
      File.write(File.join(destination_root, "app/javascript/controllers/application.js"), "")

      Rails.application.config.root = destination_root
      yield
    end
end
