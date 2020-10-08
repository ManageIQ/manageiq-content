if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[ManageIQ::AutomationEngine::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include Spec::Support::AutomationHelper

  config.before(:suite) do
    puts "** Resetting #{ENV["AUTOMATE_DOMAINS"]} domain(s)"
    Tenant.seed
    MiqAeDatastore.reset
    MiqAeDatastore.reset_to_defaults
  end

  config.around(:each) do |ex|
    begin
      ex.run
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
end

ENV["AUTOMATE_DOMAINS"] = "ManageIQ" # Reset only the ManageIQ automate domain when testing.

require "manageiq-content"
