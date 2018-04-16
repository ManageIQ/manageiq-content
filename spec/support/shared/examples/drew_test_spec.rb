RSpec.shared_examples "automate_engine_call" do |filename|
  it "drew test" do
    begin
      original_program_name = $PROGRAM_NAME
      file = ManageIQ::Content::Engine.root.join(filename).to_s
      $PROGRAM_NAME = file

      expect(described_class).to receive(:new).and_return(double(:main => nil))
      load(file)
    ensure
      $PROGRAM_NAME = original_program_name
    end
  end
end
