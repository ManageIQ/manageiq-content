require_domain_file

describe ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility do
  it "convert. in name to underscore" do
    expect(described_class.normalize_name("abc.123")).to eq("abc_123")
  end
end
