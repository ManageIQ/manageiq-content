require_domain_file

describe ManageIQ::Automate::PhysicalInfrastructure::PhysicalServer::Provisioning::StateMachines::Methods::CheckProvision do
  let(:admin)       { FactoryBot.create(:user_admin) }
  let(:server)      { FactoryBot.create(:physical_server) }
  let(:svc_server)  { MiqAeMethodService::MiqAeServicePhysicalServer.find_by(:id => server.id) }
  let(:request)     { FactoryBot.create(:physical_server_provision_request, :requester => admin) }
  let(:task)        { FactoryBot.create(:physical_server_provision_task, :miq_request => request, :source => server) }
  let(:svc_task)    { MiqAeMethodService::MiqAeServiceMiqProvisionTask.find_by(:id => task.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(:physical_server_provision_task => svc_task) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  describe 'check provision status' do
    context 'provisioning completed' do
      before { task.update!(:state => 'provisioned', :status => 'Ok') }
      it 'refreshes the request status' do
        described_class.new(ae_service).main
        expect(root_object['ae_result']).to eq('ok')
      end
    end

    context 'provisioning failed' do
      before { task.update!(:state => 'finished', :status => 'Error', :message => 'Error: because') }
      it 'refreshes the request status' do
        described_class.new(ae_service).main
        expect(root_object['ae_result']).to eq('error')
        expect(root_object['ae_reason']).to eq('because')
      end
    end

    context 'provisioning running' do
      before { task.update!(:state => 'active', :status => 'Ok') }
      it 'retries the current step' do
        described_class.new(ae_service).main
        expect(root_object['ae_result']).to eq('retry')
        expect(root_object['ae_retry_interval']).to eq('1.minute')
      end
    end
  end
end
