# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/content/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-content"
  spec.version       = ManageIQ::Content::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Content plugin for ManageIQ."
  spec.description   = "Content plugin for ManageIQ."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-content"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "savon", "~>2.11.1" # Because users expect it to be there for custom code

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
