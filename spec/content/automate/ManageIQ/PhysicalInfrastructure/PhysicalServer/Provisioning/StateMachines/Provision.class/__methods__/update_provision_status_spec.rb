require_domain_file

describe ManageIQ::Automate::PhysicalInfrastructure::PhysicalServer::Provisioning::StateMachines::Provision::UpdateProvisionStatus do
  let(:admin)       { FactoryBot.create(:user_admin) }
  let(:server)      { FactoryBot.create(:physical_server) }
  let(:svc_server)  { MiqAeMethodService::MiqAeServicePhysicalServer.find_by(:id => server.id) }
  let(:request)     { FactoryBot.create(:physical_server_provision_request, :requester => admin) }
  let(:task)        { FactoryBot.create(:physical_server_provision_task, :miq_request => request, :source => server) }
  let(:svc_task)    { MiqAeMethodService::MiqAeServiceMiqProvisionTask.find_by(:id => task.id) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(:physical_server_provision_task => svc_task) }
  let(:ae_service)  { Spec::Support::MiqAeMockService.new(root_object) }

  subject { described_class.new(ae_service) }

  describe '#status_param' do
    before { ae_service.inputs['status'] = 'the status' }
    it { expect(subject.status_param).to eq('the status') }
  end

  describe '#task' do
    it 'when all ok' do
      expect(subject.task).to eq(svc_task)
    end

    context 'when no task' do
      let(:svc_task) { nil }
      it 'is stopped' do
        expect { subject.task } .to raise_error(SystemExit)
      end
    end

    context 'when no task.source' do
      let(:server) { nil }
      it 'is stopped' do
        expect { subject.task } .to raise_error(SystemExit)
      end
    end
  end

  describe '#main' do
    before do
      ae_service.inputs['status'] = 'the status'
      root_object['miq_server'] = double('MIQ_SERVER', :name => 'miq server name')
      root_object['ae_state'] = 'at state'
    end
    context 'when no error' do
      it 'updates task and request message' do
        subject.main
        expect(task.reload.message).to eq('the status')
        request_msg = request.reload.options[:user_message]
        expect(request_msg).to include('[miq server name]')
        expect(request_msg).to include("PhysicalServer [#{server.id}|#{server.ems_ref}]")
        expect(request_msg).to include('Step [at state]')
        expect(request_msg).to include('Message [the status]')
      end
    end

    context 'when error' do
      before { root_object['ae_result'] = 'error' }
      it 'fires notification' do
        expect(subject).to receive(:fire_notification)
        subject.main
      end
    end
  end
end
