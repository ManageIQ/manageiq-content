require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::CreateVmImportRequest do
  let(:user)        { FactoryBot.create(:user_admin) }
  let(:vm)          { FactoryBot.create(:vm_vmware) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_vm)   { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(vm.id) }

  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  context 'without drivers ISO specified' do
    let(:root_hash) do
      {
        :vm              => svc_model_vm,
        :user            => svc_model_user,
        :dialog_name     => 'my_vm',
        :dialog_provider => 1,
        :dialog_cluster  => 2,
        :dialog_storage  => 3,
        :dialog_sparse   => true
      }
    end

    it 'Executes create_automation_request with correct params' do
      exp_options = {
        :namespace     => 'Infrastructure/VM/Transform/StateMachines',
        :class_name    => 'VmImport',
        :instance_name => 'default',
        :message       => 'create',
        :attrs         => {
          'Vm::vm'      => vm.id,
          'name'        => 'my_vm',
          'provider_id' => 1,
          'cluster_id'  => 2,
          'storage_id'  => 3,
          'sparse'      => true,
          'drivers_iso' => nil,
        },
        :user_id       => user.id
      }
      exp_auto_approve = true
      expect(ae_service).to receive(:execute).with('create_automation_request', exp_options, user.userid, exp_auto_approve)

      described_class.new(ae_service).main
    end
  end

  context 'with drivers ISO specified' do
    let(:root_hash) do
      {
        :vm                     => svc_model_vm,
        :user                   => svc_model_user,
        :dialog_name            => 'my_vm',
        :dialog_provider        => 1,
        :dialog_cluster         => 2,
        :dialog_storage         => 3,
        :dialog_sparse          => true,
        :dialog_install_drivers => true,
        :dialog_drivers_iso     => 'RHEV-toolsSetup_4.1_5.iso'
      }
    end

    it 'Executes create_automation_request with correct params' do
      exp_options = {
        :namespace     => 'Infrastructure/VM/Transform/StateMachines',
        :class_name    => 'VmImport',
        :instance_name => 'default',
        :message       => 'create',
        :attrs         => {
          'Vm::vm'      => vm.id,
          'name'        => 'my_vm',
          'provider_id' => 1,
          'cluster_id'  => 2,
          'storage_id'  => 3,
          'sparse'      => true,
          'drivers_iso' => 'RHEV-toolsSetup_4.1_5.iso',
        },
        :user_id       => user.id
      }
      exp_auto_approve = true
      expect(ae_service).to receive(:execute).with('create_automation_request', exp_options, user.userid, exp_auto_approve)

      described_class.new(ae_service).main
    end
  end
end
