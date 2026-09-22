require "test_helper"
require "json"

class PackagingTest < ActiveSupport::TestCase
  # Bundled apps install the npm package, the generator pins it to the gem's
  # version, and both are published from the same tag. Drift between these two
  # numbers is the one thing that breaks an install outright.
  test "the npm package carries the gem's version" do
    assert_equal TurboForm::VERSION, package_json["version"]
  end

  private
    def package_json
      JSON.parse(File.read(File.expand_path("../../package.json", __dir__)))
    end
end
