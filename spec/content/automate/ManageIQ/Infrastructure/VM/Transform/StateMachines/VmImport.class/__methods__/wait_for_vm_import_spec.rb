require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::StateMachines::WaitForVmImport do
  let(:new_ems_ref) { '/api/vms/6820ad2a-a8c0-4b4e-baf2-3482357ba352' }

  let(:root_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object, 'new_ems_ref' => new_ems_ref) }

  context 'On missing import status' do
    let!(:vm) { FactoryGirl.create(:vm_redhat, :ems_ref => new_ems_ref) }

    it 'Exits with retry' do
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq(30.minutes)
    end
  end

  context 'On successful import status' do
    let!(:custom_attribute) { FactoryGirl.create(:miq_custom_attribute, :name => 'import_status', :value => 'success') }
    let!(:vm)               { FactoryGirl.create(:vm_redhat, :ems_ref => new_ems_ref, :custom_attributes => [custom_attribute]) }

    it 'Exits with success' do
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('ok')
      expect(ae_service.get_state_var('imported_vm_id')).to eq(vm.id)
    end
  end

  context 'On failed import status' do
    let!(:custom_attribute) { FactoryGirl.create(:miq_custom_attribute, :name => 'import_status', :value => 'failure') }
    let!(:vm)               { FactoryGirl.create(:vm_redhat, :ems_ref => new_ems_ref, :custom_attributes => [custom_attribute]) }

    it 'Exits with failure' do
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('error')
    end
  end
end
