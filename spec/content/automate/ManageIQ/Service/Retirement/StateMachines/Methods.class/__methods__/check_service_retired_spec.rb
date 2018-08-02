require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::Methods::CheckServiceRetired do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:request) { FactoryGirl.create(:service_retire_request, :requester => admin) }
  let(:service) { FactoryGirl.create(:service) }
  let(:task) { FactoryGirl.create(:service_retire_task, :destination => service, :miq_request => request) }
  let(:svc_task) { MiqAeMethodService::MiqAeServiceServiceRetireTask.find(task.id) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }
  let(:vm) { FactoryGirl.create(:vm) }
  let(:retired_vm) { FactoryGirl.create(:vm, :retired => true) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service'             => svc_service,
                                       'service_retire_task' => svc_task,
                                       'service_action'      => 'Retirement')
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }

  context "with non retired resource" do
    it "check" do
      service.service_resources << FactoryGirl.create(:service_resource, :resource_type => "VmOrTemplate", :service_id => service.id, :resource_id => vm.id)
      expect(ae_service).to receive(:log).exactly(4).times
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('retry')
    end
  end

  context " with retired resource" do
    it "check" do
      service.service_resources << FactoryGirl.create(:service_resource, :resource_type => "VmOrTemplate", :service_id => service.id, :resource_id => retired_vm.id)
      expect(ae_service).to receive(:log).exactly(3).times
      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq('ok')
    end
  end

  context "nil service" do
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service'             => nil,
                                         'service_retire_task' => task,
                                         'service_action'      => 'Retirement')
    end
    it "check" do
      expect { described_class.new(ae_service).main }.to raise_error('Service object has not been provided')
    end
  end
end
