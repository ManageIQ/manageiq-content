require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/TransformationHosts/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::TransformationThrottler::Utils do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:automation_task) { FactoryGirl.create(:automation_task) }
  let(:automation_request_1) { FactoryGirl.create(:automation_request) }
  let(:automation_request_2) { FactoryGirl.create(:automation_request) }
  let(:automation_request_3) { FactoryGirl.create(:automation_request) }
  let(:transformation_task_1) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:transformation_task_2) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:host) { FactoryGirl.create(:host) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_automation_task) { MiqAeMethodService::MiqAeServiceAutomationTask.find(automation_task.id) }
  let(:svc_model_automation_request_1) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_1.id) }
  let(:svc_model_automation_request_2) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_2.id) }
  let(:svc_model_automation_request_3) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_3.id) }
  let(:svc_model_transformation_task_1) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(transformation_task_1.id) }
  let(:svc_model_transformation_task_2) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(transformation_task_2.id) }
  let(:svc_model_host) { MiqAeMethodService::MiqAeServiceHost.find(host.id) }

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

  before(:each) do
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@task, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@current_throttler, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@active_throttlers, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@throttler_election_policy, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@throttler_type, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@throttler_ttl, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@tasks_scheduling_policy, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@limits_adjustment_policy, nil)
    ManageIQ::Automate::Transformation::TransformationThrottler::Utils.instance_variable_set(:@active_transformation_tasks, nil)

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

    it "filter out invalid request" do
      allow(ae_service).to receive(:vmdb).with(:miq_request).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:request_state => 'active', :type => 'AutomationRequest').and_return([svc_model_automation_request_1, svc_model_automation_request_3])
      expect(described_class.active_throttlers(ae_service).length).to eq(1)
      expect(described_class.active_throttlers(ae_service).first.id).to eq(svc_model_automation_request_1.id)
    end
  end

  context "#throttler_election_policy" do
    it "without policy" do
      expect(described_class.throttler_election_policy(ae_service)).to eq('eldest_active')
    end

    it "with policy" do
      ae_service.root['throttler_election_policy'] = 'smarter'
      expect(described_class.throttler_election_policy(ae_service)).to eq('smarter')
    end
  end

  context "#elected_throttler?" do
    it "check send correct method" do
      expect(described_class).to receive(:eldest_active_throttler?).with(ae_service)
      described_class.elected_throttler?(ae_service)
    end
  end

  context "#eldest_active_throttler?" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceAutomationRequest }

    before do
      ae_service.root['automation_task'] = svc_model_automation_task
      allow(ae_service).to receive(:vmdb).with(:miq_request).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:request_state => 'active', :type => 'AutomationRequest').and_return([svc_model_automation_request_1, svc_model_automation_request_2])
    end

    it "is not eldest active throttler" do
      allow(svc_model_automation_task).to receive(:miq_request).and_return(svc_model_automation_request_2)
      expect(described_class.eldest_active_throttler?(ae_service)).to eq(false)
    end

    it "is eldest active throttler" do
      allow(svc_model_automation_task).to receive(:miq_request).and_return(svc_model_automation_request_1)
      expect(described_class.eldest_active_throttler?(ae_service)).to eq(true)
    end
  end

  context "#throttler_ttl" do
    it "without ttl" do
      expect(described_class.throttler_ttl(ae_service)).to eq(3600)
    end

    it "with type" do
      ae_service.root['throttler_ttl'] = 86_400
      expect(described_class.throttler_ttl(ae_service)).to eq(86_400)
    end
  end

  context "#throttler_type" do
    it "without type" do
      expect(described_class.throttler_type(ae_service)).to eq('Default')
    end

    it "with type" do
      ae_service.root['throttler_type'] = 'Custom'
      expect(described_class.throttler_type(ae_service)).to eq('Custom')
    end
  end

  context "#launch" do
    it "with default values" do
      expect(ae_service).to receive(:execute).with(
        :create_automation_request,
        {
          :namespace     => 'Transformation/StateMachines',
          :class_name    => 'TransformationThrottler',
          :instance_name => 'Default',
          :user_id       => 1,
          :attrs         => { :ttl => 3600 }
        },
        'admin',
        true
      )
      described_class.launch(ae_service)
    end
  end

  context "#retry_or_die" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    before do
      ae_service.root['automation_task'] = svc_model_automation_task
      allow(svc_model_automation_task).to receive(:miq_request).and_return(svc_model_automation_request_1)
    end

    it "ttl reached" do
      allow(svc_model_automation_request_1).to receive(:created_on).and_return(Time.now.utc + 60)
      described_class.retry_or_die(ae_service)
      expect(ae_service.root['ae_result']).to be_nil
    end

    it "without active transformation task" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([])
      described_class.retry_or_die(ae_service)
      expect(ae_service.root['ae_result']).to be_nil
    end

    it "with active transformation task" do
      ae_service.root['ae_state_max_retries'] = 60
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1])
      described_class.retry_or_die(ae_service)
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq(60.seconds)
    end
  end

  context "#tasks_scheduling_policy" do
    it "without policy" do
      expect(described_class.tasks_scheduling_policy(ae_service)).to eq('fifo')
    end

    it "with policy" do
      ae_service.root['tasks_scheduling_policy'] = 'smarter'
      expect(described_class.tasks_scheduling_policy(ae_service)).to eq('smarter')
    end
  end

  context "#schedule_tasks" do
    it "check send correct method" do
      expect(described_class).to receive(:schedule_tasks_fifo).with(ae_service)
      described_class.schedule_tasks(ae_service)
    end
  end

  context "#schedule_tasks_fifo" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "only one slot available" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1, svc_model_transformation_task_2])
      allow(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:get_transformation_host).and_return(['OVirtHost', svc_model_host, 'vddk'], [nil, nil, nil])
      described_class.schedule_tasks_fifo(ae_service)
      expect(svc_model_transformation_task_1.get_option(:transformation_host_id)).to eq(svc_model_host.id)
      expect(svc_model_transformation_task_1.get_option(:transformation_host_name)).to eq(svc_model_host.name)
      expect(svc_model_transformation_task_1.get_option(:transformation_host_type)).to eq('OVirtHost')
      expect(svc_model_transformation_task_1.get_option(:transformation_method)).to eq('vddk')
      expect(svc_model_transformation_task_2.get_option(:transformation_host_id)).to be_nil
      expect(svc_model_transformation_task_2.get_option(:transformation_host_name)).to be_nil
      expect(svc_model_transformation_task_2.get_option(:transformation_host_type)).to be_nil
      expect(svc_model_transformation_task_2.get_option(:transformation_method)).to be_nil
    end
  end

  context "#limits_adjustment_policy" do
    it "without policy" do
      expect(described_class.limits_adjustment_policy(ae_service)).to eq('skip')
    end

    it "with policy" do
      ae_service.root['limits_adjustment_policy'] = 'smarter'
      expect(described_class.limits_adjustment_policy(ae_service)).to eq('smarter')
    end
  end

  context "#adjust_limits" do
    it "check send correct method" do
      expect(described_class).to receive(:adjust_limits_skip).with(ae_service)
      described_class.adjust_limits(ae_service)
    end
  end

  context "#active_transformation_tasks" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "without active transformation task" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([])
      expect(described_class.active_transformation_tasks(ae_service)).to eq([])
    end

    it "with active transformation task" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1])
      expect(described_class.active_transformation_tasks(ae_service).first.id).to eq(svc_model_transformation_task_1.id)
    end
  end

  context "#unassigned_transformation_tasks" do
    let(:svc_vmdb_handle) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

    it "filter out assigned transformation task" do
      allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle)
      allow(svc_vmdb_handle).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1, svc_model_transformation_task_2])
      allow(svc_model_transformation_task_1).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_host.id)
      expect(described_class.unassigned_transformation_tasks(ae_service).length).to eq(1)
      expect(described_class.unassigned_transformation_tasks(ae_service).first.id).to eq(svc_model_transformation_task_2.id)
    end
  end
end
