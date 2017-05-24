require_domain_file

describe ManageIQ::Automate::System::Event::EmsEvent::RHEVM::UpdateVmImportStatus do
  let(:user)       { FactoryGirl.create(:user_with_group) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:ems)        { FactoryGirl.create(:ems_redhat) }
  let(:vm)         { FactoryGirl.create(:vm_redhat) }

  let(:ems_event) do
    FactoryGirl.create(:ems_event, :vm_or_template => vm, :ext_management_system => ems)
  end
  let(:svc_model_miq_server) { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:svc_model_user)       { MiqAeMethodService::MiqAeServiceUser.find(user.id) }

  let(:root_hash) do
    {
      'user'         => svc_model_user,
      'miq_server'   => svc_model_miq_server,
      'event_stream' => MiqAeMethodService::MiqAeServiceEmsEvent.find(ems_event.id),
      'event_type'   => event_type
    }
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

  context 'on IMPORTEXPORT_IMPORT_VM_FAILED received' do
    let(:event_type) { 'IMPORTEXPORT_IMPORT_VM_FAILED' }

    it 'updates VM import status to failure' do
      described_class.new(ae_service).main

      expect(vm.miq_custom_get('import_status')).to eq('failure')
    end
  end

  context 'on IMPORTEXPORT_IMPORT_VM received' do
    let(:event_type) { 'IMPORTEXPORT_IMPORT_VM' }

    it 'updates VM import status to success' do
      described_class.new(ae_service).main

      expect(vm.miq_custom_get('import_status')).to eq('success')
    end
  end
end
