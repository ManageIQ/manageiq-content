require_domain_file

describe ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility do
  context "class method" do
    it "convert. in name to underscore" do
      expect(described_class.normalize_name("abc.123")).to eq("abc_123")
    end

    it "raises exception with nil" do
      expect do
        described_class.normalize_name(nil)
      end.to raise_error(ArgumentError)
    end
  end

  context "instance method" do
    it "convert . in name to underscore" do
      obj = described_class.new("abc.123")
      expect(obj.normalize).to eq("abc_123")
    end
  end
end
