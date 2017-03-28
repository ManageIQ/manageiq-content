desc "Clean YAML files for consistent whitespace and formatting"
task :clean_yaml_files do
  yaml_files = ManageIQ::Content::Engine.root.join("content/**/*.yaml")
  Dir.glob(yaml_files).sort.each do |f|
    content = File.read(f)
    yaml_content = YAML.load(content).to_yaml
    if content != yaml_content
      puts "Fixing #{Pathname.new(f).relative_path_from(ManageIQ::Content::Engine.root)}"
      File.write(f, yaml_content)
    end
  end
end
