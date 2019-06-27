require 'simplecov'
SimpleCov.start

if ENV["TRAVIS"] || ENV['CI']
  require 'coveralls'
  Coveralls.wear!('rails') { add_filter("/spec/") }
end

ENV["RAILS_ENV"] ||= 'test'
ENV["AUTOMATE_DOMAINS"] = "ManageIQ" # Reset only the ManageIQ automate domain when testing.

require File.expand_path('manageiq/config/environment', __dir__)
require 'rspec/rails'

def require_domain_file
  spec_name = caller_locations(1..1).first.path
  file_name = spec_name.sub("spec/", "").sub("_spec.rb", ".rb")
  AutomateClassDefinitionHook.require_with_hook(file_name)
end

# Requires supporting ruby files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
Dir[ManageIQ::AutomationEngine::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[ManageIQ::Content::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include Spec::Support::AutomationHelper
  config.include Spec::Support::RakeTaskExampleGroup, :type => :rake_task

  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |c|
    c.allow_message_expectations_on_nil = false
    c.syntax = :expect
  end

  config.before(:suite) do
    puts "** Resetting #{ENV["AUTOMATE_DOMAINS"]} domain(s)"
    Tenant.seed
    MiqAeDatastore.reset
    MiqAeDatastore.reset_to_defaults
  end

  config.before do
    EmsRefresh.try(:debug_failures=, true)
  end

  config.around(:each) do |ex|
    begin
      EvmSpecHelper.clear_caches { ex.run }
    rescue SystemExit => e
      STDERR.puts
      STDERR.puts "Kernel.exit called from:"
      STDERR.puts e.backtrace
      exit 1
    end
  end

  config.after(:suite) do
    MiqAeDatastore.reset
  end

  unless ENV['CI']
    # File store for --only-failures option
    config.example_status_persistence_file_path = Rails.root.join('tmp', 'rspec_example_store.txt')
  end

  if config.backtrace_exclusion_patterns.delete(%r{/lib\d*/ruby/})
    config.backtrace_exclusion_patterns << %r{/lib\d*/ruby/[0-9]}
  end

  config.backtrace_exclusion_patterns << %r{/spec/spec_helper}
  config.backtrace_exclusion_patterns << %r{/spec/support/evm_spec_helper}
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
