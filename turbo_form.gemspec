require_relative "lib/turbo_form/version"

Gem::Specification.new do |spec|
  spec.name        = "turbo_form"
  spec.version     = TurboForm::VERSION
  spec.authors     = [ "Andy Cohen" ]
  spec.email       = [ "outlawandy@gmail.com" ]
  spec.homepage    = "TODO"
  spec.summary     = "Turbo-Stream backed dynamic forms, by convention."
  spec.description = "Zero-configuration Turbo-Stream backed dynamic forms for Rails."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "actionpack", ">= 7.1.0"
  spec.add_dependency "railties", ">= 7.1.0"
end
