require 'simplecov'
SimpleCov.start

require 'manageiq-content'

# Reset only the ManageIQ automate domain when testing.
ENV["AUTOMATE_DOMAINS"] = "ManageIQ"

def require_domain_file
  spec_name = caller_locations.first.path
  file_name = spec_name.sub("spec/", "").sub("_spec.rb", ".rb")

  AutomateClassDefinitionHook.require_with_hook(file_name)
end

def domain_file
  caller_locations(1..1).first.path.sub("spec/", "").sub("_spec.rb", ".rb")
end

Dir[ManageIQ::AutomationEngine::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[ManageIQ::Content::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include Spec::Support::AutomationHelper

  config.around(:example) do |ex|
    begin
      ex.run
    rescue SystemExit => e
      STDERR.puts
      STDERR.puts "Kernel.exit called from:"
      STDERR.puts e.backtrace
      exit 1
    end
  end

  config.before(:suite) do
    puts "** Resetting #{ENV["AUTOMATE_DOMAINS"]} domain(s)"
    Tenant.seed
    MiqAeDatastore.reset
    MiqAeDatastore.reset_to_defaults
  end

  config.after(:suite) do
    MiqAeDatastore.reset
  end
end

module AutomateClassDefinitionHook
  mattr_accessor :hooking

  def self.hooked
    @hooked ||= []
  end

  def inherited(other)
    AutomateClassDefinitionHook.hook(other)
    super
  end

  def self.require_with_hook(file_name)
    self.hooking = true
    require(file_name).tap { unhook }
  end

  class TestLoadStub
    def main
    end
  end

  def self.hook(klass)
    return unless hooking
    if klass.name&.start_with?("ManageIQ::Automate::")
      hooked << klass
      klass.define_singleton_method(:new) { |*_args| AutomateClassDefinitionHook::TestLoadStub.new }
    end
  end

  def self.unhook
    hooked.delete_if { |klass| klass.singleton_class.send(:remove_method, :new) }
    self.hooking = false
  end
end

Object.singleton_class.prepend(AutomateClassDefinitionHook)
