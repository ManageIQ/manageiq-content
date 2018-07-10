require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::Profile::GetDeployDialog do
  let(:cat)         { 'environment' }
  let(:tag)         { 'dev' }
  let(:root_hash)   { { 'dialog_input_vm_tags' => "#{cat}/#{tag}" } }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it 'sets dialog name in the root object' do
    described_class.new(ae_service).main(true)
    expect(ae_service.root['dialog_name']).to(eq("miq_provision_dialogs-deploy-#{tag}"))
  end

  context 'does not set dialog name' do
    it '#not matching dialog_input_vm_tags attribute' do
      ae_service.root['dialog_input_vm_tags'] = 'not_matching_string'
      described_class.new(ae_service).main(true)
      expect(ae_service.root['dialog_name']).to(eq(nil))
    end

    it '#run_env_dialog flag is false' do
      expect(ae_service).not_to(receive(:log))
      described_class.new(ae_service).main
      expect(ae_service.root['dialog_name']).to(eq(nil))
    end
  end
end
