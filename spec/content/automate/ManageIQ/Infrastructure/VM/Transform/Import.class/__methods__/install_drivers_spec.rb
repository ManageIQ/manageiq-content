require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::InstallDrivers do
  let(:operating_system) { FactoryBot.create(:operating_system, :product_name => os_name) }
  let(:vm)               { FactoryBot.create(:vm_vmware, :operating_system => operating_system) }
  let(:svc_model_vm)     { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(vm.id) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(:vm => svc_model_vm)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  context 'for windows VM' do
    let(:os_name) { 'Windows 10' }

    it 'should pre-check the checkbox' do
      described_class.new(ae_service).main

      expect(ae_service.object['value']).to eq('t')
      expect(ae_service.object['read_only']).to eq(false)
      expect(ae_service.object['visible']).to eq(true)
    end
  end

  context 'for linux VM' do
    let(:os_name) { 'RHEL 7' }

    it 'should leave the checkbox unchecked' do
      described_class.new(ae_service).main

      expect(ae_service.object['value']).to eq('f')
      expect(ae_service.object['read_only']).to eq(false)
      expect(ae_service.object['visible']).to eq(true)
    end
  end

  context 'for undefined OS' do
    let(:operating_system) { nil }

    it 'should leave the checkbox unchecked' do
      described_class.new(ae_service).main

      expect(ae_service.object['value']).to eq('f')
      expect(ae_service.object['read_only']).to eq(false)
      expect(ae_service.object['visible']).to eq(true)
    end
  end
end
