def require_domain_file
  spec_name = caller_locations(1..1).first.path
  file_name = spec_name.sub("spec/", "").sub("_spec.rb", ".rb")
  AutomateClassDefinitionHook.require_with_hook(file_name)
end
