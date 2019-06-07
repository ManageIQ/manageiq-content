source 'https://rubygems.org'

gemspec

# Load Gemfile with dependencies from manageiq
manageiq_gemfile = File.expand_path("spec/manageiq/Gemfile", __dir__)

gem 'manageiq-automation_engine', :github => "jrafanie/manageiq-automation_engine", :branch => "rails-5-1"
if File.exist?(manageiq_gemfile)
  eval_gemfile(manageiq_gemfile)
else
  puts "ERROR: The ManageIQ application must be present in spec/manageiq."
  puts "  Clone it from GitHub or symlink it from local source."
  exit 1
end
