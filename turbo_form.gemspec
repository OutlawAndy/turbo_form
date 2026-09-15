require_relative "lib/turbo_form/version"

Gem::Specification.new do |spec|
  spec.name        = "turbo_form"
  spec.version     = TurboForm::VERSION
  spec.authors     = [ "Andy Cohen" ]
  spec.email       = [ "outlawandy@gmail.com" ]
  spec.homepage    = "https://github.com/outlawandy/turbo_form"
  spec.summary     = "Turbo-Stream backed dynamic forms, by convention."
  spec.description = "Zero-configuration Turbo-Stream backed dynamic forms for Rails."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "actionview", ">= 7.1.0"
  spec.add_dependency "activesupport", ">= 7.1.0"
  spec.add_dependency "railties", ">= 7.1.0"
  spec.add_dependency "turbo-rails", ">= 2.0.0"
end
