$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "manageiq/content/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "manageiq-content"
  s.version     = ManageIQ::Content::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-content"
  s.summary     = "Default ManageIQ content"
  s.description = "Default ManageIQ content"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{content,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  s.add_development_dependency "codeclimate-test-reporter"
  s.add_development_dependency "simplecov"
end
