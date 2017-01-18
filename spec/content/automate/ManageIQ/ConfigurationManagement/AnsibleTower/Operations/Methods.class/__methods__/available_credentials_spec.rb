require_domain_file

describe ManageIQ::Automate::ConfigurationManagement::AnsibleTower::Operations::AvailableCredentials do
  let(:root_hash) do
    { 'service_template' => MiqAeMethodService::MiqAeServiceServiceTemplate.find(service_template.id) }
  end
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  shared_examples_for "#having only default value" do
    let(:default_desc_blank) { "<none>" }

    it "provides only default value to the image list" do
      described_class.new(ae_service).main
     
      expect(ae_service["values"]).to eq(nil => default_desc_blank)
      expect(ae_service["default_value"]).to be_nil
    end
  end

  context "empty list" do
    let(:root_hash) { }

    it_behaves_like "#having only default value"
  end
end
