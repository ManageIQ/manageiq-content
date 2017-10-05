require_domain_file

describe ManageIQ::Automate::System::CommonMethods::QuotaMethods::Used do
  include Spec::Support::QuotaHelper

  let!(:model) { setup_model }
  let(:root_hash) do
    {
      'miq_provision_request' => @miq_provision_request,
      'miq_request'           => @miq_provision_request,
      'quota_source'          => quota_source,
      'quota_source_type'     => quota_source_type
    }
  end

  let(:counts_hash) do
    {:storage => 1_000_000, :cpu => 0, :vms => 4, :memory => 1_073_741_824}
  end

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(root_hash)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  shared_examples_for "used" do
    it "check" do
      described_class.new(ae_service).main
      expect(ae_service.root['quota_used']).to include(counts_hash)
    end
  end

  context "returns ok for tenant counts" do
    let(:quota_source) { @tenant }
    let(:quota_source_type) { 'tenant' }
    it_behaves_like "used"
  end

  context "returns ok for user counts" do
    let(:quota_source) { @tenant }
    let(:quota_source_type) { 'user' }
    it_behaves_like "used"
  end

  context "returns ok for group counts" do
    let(:quota_source) { @tenant }
    let(:quota_source_type) { 'group' }
    it_behaves_like "used"
  end

  context "returns error " do
    let(:quota_source_type) { nil }
    let(:quota_source) { nil }
    let(:errormsg) { 'ERROR - quota_source not found' }
    it "when no quota source" do
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
    end
  end
end
