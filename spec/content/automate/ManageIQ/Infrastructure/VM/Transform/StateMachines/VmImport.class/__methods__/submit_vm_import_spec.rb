require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::StateMachines::SubmitVmImport do
  let(:user)        { FactoryBot.create(:user_admin) }
  let(:vm)          { FactoryBot.create(:vm_vmware) }
  let(:provider)    { FactoryBot.create(:ems_redhat) }

  let(:svc_model_user)     { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_vm)       { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(vm.id) }
  let(:svc_model_provider) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager.find(provider.id) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
      :user        => svc_model_user,
      :vm          => svc_model_vm,
      :name        => 'my_vm',
      :provider_id => provider.id,
      :cluster_id  => 1,
      :storage_id  => 2,
      :sparse      => true
    )
  end

  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  let(:new_ems_ref) { '/api/vms/6820ad2a-a8c0-4b4e-baf2-3482357ba352' }

  it 'Calls :submit_import_vm on the provider object with correct params' do
    allow(ae_service).to receive(:vmdb).with(:ext_management_system, provider.id).and_return(svc_model_provider)

    expect(svc_model_provider).to receive(:submit_import_vm).with(
      user.userid,
      vm.id,
      :name        => 'my_vm',
      :cluster_id  => 1,
      :storage_id  => 2,
      :sparse      => true,
      :drivers_iso => nil
    ).and_return(new_ems_ref)

    described_class.new(ae_service).main

    expect(ae_service.get_state_var('new_ems_ref')).to eq(new_ems_ref)
  end
end
