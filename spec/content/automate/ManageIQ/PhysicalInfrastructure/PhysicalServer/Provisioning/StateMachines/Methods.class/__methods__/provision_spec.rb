require_domain_file

describe ManageIQ::Automate::PhysicalInfrastructure::PhysicalServer::Provisioning::StateMachines::Methods::Provision do
  let(:admin)       { FactoryBot.create(:user_admin) }
  let(:server)      { FactoryBot.create(:physical_server) }
  let(:svc_server)  { MiqAeMethodService::MiqAeServicePhysicalServer.find_by(:id => server.id) }
  let(:request)     { FactoryBot.create(:physical_server_provision_request, :requester => admin) }
  let(:task)        { FactoryBot.create(:physical_server_provision_task, :miq_request => request, :source => server) }
  let(:svc_task)    { MiqAeMethodService::MiqAeServiceMiqProvisionTask.find_by(:id => task.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(:physical_server_provision_task => svc_task) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  it 'calls execute on task' do
    expect(svc_task).to receive(:execute)
    described_class.new(ae_service).main
  end
end
