require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::StateMachines::ConfigureVmNetworks do
  let(:user)        { FactoryBot.create(:user_admin) }
  let(:provider)    { FactoryBot.create(:ems_redhat) }

  let(:svc_model_user)     { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_provider) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Redhat_InfraManager.find(provider.id) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
      :user        => svc_model_user,
      :name        => 'my_vm',
      :provider_id => provider.id
    )
  end

  let(:vm_id) { 42 }

  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object, 'imported_vm_id' => vm_id) }

  it 'Calls :submit_import_vm on the provider object with correct params' do
    allow(ae_service).to receive(:vmdb).with(:ext_management_system, provider.id).and_return(svc_model_provider)

    expect(svc_model_provider).to receive(:submit_configure_imported_vm_networks).with(user.userid, vm_id)

    described_class.new(ae_service).main
  end
end
