require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::Methods::CheckServiceRetired do
  let(:admin) { FactoryBot.create(:user_admin) }
  let(:request) { FactoryBot.create(:service_retire_request, :requester => admin) }
  let(:service) { FactoryBot.create(:service) }
  let(:task) { FactoryBot.create(:service_retire_task, :destination => service, :miq_request => request, :message => 'fred') }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceRetireTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'             => svc_service,
                                       'service_retire_task' => svc_task,
                                       'service_action'      => 'Retirement')
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  context "with non finished task" do
    it "check" do
      task.miq_request_tasks << FactoryBot.create(:service_retire_task, :miq_request => request, :state => 'active')
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('retry')
    end
  end

  context " with finished task" do
    it "check" do
      task.miq_request_tasks << FactoryBot.create(:service_retire_task, :miq_request => request, :state => 'finished')
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('ok')
    end
  end

  context " with error task" do
    it "check" do
      task.miq_request_tasks << FactoryBot.create(:service_retire_task, :miq_request => request, :state => 'pending')
      expect(svc_task).to receive(:statemachine_task_status).and_return('error')
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('error')
    end
  end
end
