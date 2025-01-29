describe "YAML files" do
  it "should be programatically generated" do
    yaml_files = ManageIQ::Content::Engine.root.join("content/**/*.yaml")
    invalid_files = Dir.glob(yaml_files).sort.select do |f|
      content = File.read(f)
      yaml_content = YAML.load(content).to_yaml
      content != yaml_content
    end
    expect(invalid_files).to(be_empty, invalid_files_message(invalid_files))
  end

  def invalid_files_message(invalid_files)
    file_list = invalid_files.collect do |f|
      "./#{Pathname.new(f).relative_path_from(ManageIQ::Content::Engine.root)}"
    end.join("\n    ")

    <<-EOS
The following files appear to have been hand edited, and should be
programatically edited instead.

    #{file_list}

This allows for future exports of the domain to remain consistent without
introducing unnecessary differences in whitespace and formatting.

To fix the files, you can edit them, export them, or run the following command:

    bundle exec rake clean_yaml_files
EOS
  end
end
