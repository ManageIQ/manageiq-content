require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::Profile::VmDialogNamePrefix do
  let(:platform)        { 'test_platform' }
  let(:root_hash)       { { 'platform' => platform } }
  let(:root_object)     { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:vm_template)     { FactoryBot.create(:template_amazon) }
  let(:svc_vm_template) { MiqAeMethodService::MiqAeServiceVmOrTemplate.find(vm_template.id) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "sets dialog_name_prefix from 'root['platform']'" do
    described_class.new(ae_service).main
    expect(ae_service.object['dialog_name_prefix']).to(eq("miq_provision_#{platform}_dialogs"))
  end

  it 'sets dialog_name_prefix from vmdb' do
    ae_service.root['platform'] = nil
    ae_service.root['dialog_input_src_vm_id'] = svc_vm_template.id
    described_class.new(ae_service).main
    expect(ae_service.object['dialog_name_prefix']).to(eq("miq_provision_#{svc_vm_template.model_suffix.downcase}_dialogs"))
  end

  it 'sets default dialog_name_prefix' do
    ae_service.root['platform'] = nil
    described_class.new(ae_service).main
    expect(ae_service.object['dialog_name_prefix']).to(eq("miq_provision_vmware_dialogs"))
  end
end
