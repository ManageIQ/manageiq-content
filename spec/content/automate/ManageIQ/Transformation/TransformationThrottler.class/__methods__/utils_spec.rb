require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::TransformationThrottler::Utils do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:automation_task) { FactoryGirl.create(:automation_task) }
  let(:automation_request_1) { FactoryGirl.create(:automation_request) }
  let(:automation_request_2) { FactoryGirl.create(:automation_request) }
  let(:automation_request_3) { FactoryGirl.create(:automation_request) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_automation_task) { MiqAeMethodService::MiqAeServiceAutomationTask.find(automation_task.id) }
  let(:svc_model_automation_request_1) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_1.id) }
  let(:svc_model_automation_request_2) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_2.id) }
  let(:svc_model_automation_request_3) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_3.id) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current' => current_object,
      'user'    => svc_model_user,
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object.parent = root
      service.current_object = current_object
    end
  end

  before do
    svc_model_automation_request_1.set_option(:namespace, 'Transformation/StateMachines')
    svc_model_automation_request_1.set_option(:class_name, 'TransformationThrottler')
    svc_model_automation_request_1.set_option(:instance_name, 'Default')

    svc_model_automation_request_2.set_option(:namespace, 'Transformation/StateMachines')
    svc_model_automation_request_2.set_option(:class_name, 'TransformationThrottler')
    svc_model_automation_request_2.set_option(:instance_name, 'Default')

    svc_model_automation_request_3.set_option(:namespace, 'Transformation/StateMachines')
    svc_model_automation_request_3.set_option(:class_name, 'TransformationThrottler')
    svc_model_automation_request_3.set_option(:instance_name, 'Invalid')
  end

  before(:each) do
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@task, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@current_throttler, nil)
  end

  context "#task" do
    it "without task" do
      errormsg = 'ERROR - An automation_task is needed for this method to continue'
      expect { described_class.task(ae_service) }.to raise_error(errormsg)
    end

    it "with task" do
      ae_service.root['automation_task'] = svc_model_automation_task
      expect(described_class.task(ae_service).id).to eq(svc_model_automation_task.id)
    end
  end

  context "#current_throttler" do
    it "without request" do
      ae_service.root['automation_task'] = svc_model_automation_task
      allow(svc_model_automation_task).to receive(:miq_request).and_return(nil)
      errormsg = 'ERROR - A miq_request is needed for this method to continue'
      expect { described_class.current_throttler(ae_service) }.to raise_error(errormsg)
    end

    it "with request" do
      ae_service.root['automation_task'] = svc_model_automation_task
      allow(svc_model_automation_task).to receive(:miq_request).and_return(svc_model_automation_request_1)
      expect(described_class.current_throttler(ae_service).id).to eq(svc_model_automation_request_1.id)
    end
  end

  context "#active_throttlers" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceAutomationRequest }

    it "eliminate invalid request" do
      allow(ae_service).to receive(:vmdb).with(:miq_request).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:request_state => 'active', :type => 'AutomationRequest').and_return([svc_model_automation_request_1, svc_model_automation_request_3])
      expect(described_class.active_throttlers(ae_service).length).to eq(1)
      expect(described_class.active_throttlers(ae_service).first.id).to eq(svc_model_automation_request_1.id)
    end
  end
end
