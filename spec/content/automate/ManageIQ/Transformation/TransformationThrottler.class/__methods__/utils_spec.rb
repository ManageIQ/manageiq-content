require_domain_file

describe ManageIQ::Automate::Transformation::TransformationThrottler::Utils do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:automation_task) { FactoryBot.create(:automation_task) }
  let(:automation_request_1) { FactoryBot.create(:automation_request) }
  let(:automation_request_2) { FactoryBot.create(:automation_request) }
  let(:automation_request_3) { FactoryBot.create(:automation_request) }
  let(:src_cluster) { FactoryBot.create(:ems_cluster) }
  let(:src_vm_1) { FactoryBot.create(:vm_or_template, :ems_cluster => src_cluster) }
  let(:src_vm_2) { FactoryBot.create(:vm_or_template, :ems_cluster => src_cluster) }
  let(:src_vm_3) { FactoryBot.create(:vm_or_template, :ems_cluster => src_cluster) }
  let(:dst_ems_1) { FactoryBot.create(:ext_management_system, :api_version => '4.2.4') }
  let(:dst_ems_2) { FactoryBot.create(:ext_management_system, :api_version => '4.2.4') }
  let(:dst_cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => dst_ems_1) }
  let(:dst_host_1) { FactoryBot.create(:host_redhat, :ext_management_system => dst_ems_1) }
  let(:dst_host_2) { FactoryBot.create(:host_redhat, :ext_management_system => dst_ems_1) }
  let(:dst_host_3) { FactoryBot.create(:host_redhat, :ext_management_system => dst_ems_2) }
  let(:conversion_host_1) { FactoryBot.create(:conversion_host, :resource => dst_host_1) }
  let(:conversion_host_2) { FactoryBot.create(:conversion_host, :resource => dst_host_2) }
  let(:conversion_host_3) { FactoryBot.create(:conversion_host, :resource => dst_host_3) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_automation_task) { MiqAeMethodService::MiqAeServiceAutomationTask.find(automation_task.id) }
  let(:svc_model_automation_request_1) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_1.id) }
  let(:svc_model_automation_request_2) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_2.id) }
  let(:svc_model_automation_request_3) { MiqAeMethodService::MiqAeServiceAutomationRequest.find(automation_request_3.id) }
  let(:svc_model_src_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_cluster.id) }
  let(:svc_model_src_vm_1) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_vm_1.id) }
  let(:svc_model_src_vm_2) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_vm_2.id) }
  let(:svc_model_src_vm_3) { MiqAeMethodService::MiqAeServiceEmsCluster.find(src_vm_3.id) }
  let(:svc_model_dst_ems_1) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_1.id) }
  let(:svc_model_dst_ems_2) { MiqAeMethodService::MiqAeServiceExtManagementSystem.find(dst_ems_2.id) }
  let(:svc_model_dst_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(dst_cluster.id) }
  let(:svc_model_transformation_task_1) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(transformation_task_1.id) }
  let(:svc_model_transformation_task_2) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(transformation_task_2.id) }
  let(:svc_model_transformation_task_3) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(transformation_task_3.id) }
  let(:svc_model_conversion_host_1) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host_1.id) }
  let(:svc_model_conversion_host_2) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host_2.id) }
  let(:svc_model_conversion_host_3) { MiqAeMethodService::MiqAeServiceConversionHost.find(conversion_host_3.id) }

  let(:mapping) do
    FactoryBot.create(
      :transformation_mapping,
      :transformation_mapping_items => [
        FactoryBot.create(:transformation_mapping_item, :source => src_cluster, :destination => dst_cluster),
      ]
    )
  end

  let(:catalog_item_options) do
    {
      :name        => 'Transformation Plan',
      :description => 'a description',
      :config_info => {
        :transformation_mapping_id => mapping.id,
        :actions                   => [
          {:vm_id => src_vm_1.id.to_s, :pre_service => false, :post_service => false},
          {:vm_id => src_vm_2.id.to_s, :pre_service => false, :post_service => false},
          {:vm_id => src_vm_3.id.to_s, :pre_service => false, :post_service => false}
        ],
      }
    }
  end

  let(:plan) { ServiceTemplateTransformationPlan.create_catalog_item(catalog_item_options) }
  let(:request) { FactoryBot.create(:service_template_transformation_plan_request, :source => plan) }
  let(:transformation_task_1) { FactoryBot.create(:service_template_transformation_plan_task, :miq_request => request, :request_type => 'transformation_plan', :source => src_vm_1) }
  let(:transformation_task_2) { FactoryBot.create(:service_template_transformation_plan_task, :miq_request => request, :request_type => 'transformation_plan', :source => src_vm_2) }
  let(:transformation_task_3) { FactoryBot.create(:service_template_transformation_plan_task, :miq_request => request, :request_type => 'transformation_plan', :source => src_vm_3) }

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

  let(:svc_vmdb_handle_user) { MiqAeMethodService::MiqAeServiceUser }
  let(:svc_vmdb_handle_request) { MiqAeMethodService::MiqAeServiceAutomationRequest }
  let(:svc_vmdb_handle_conversion_host) { MiqAeMethodService::MiqAeServiceConversionHost }
  let(:svc_vmdb_handle_transformation_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask }

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

    allow(ae_service).to receive(:vmdb).with(:user).and_return(svc_vmdb_handle_user)
    allow(ae_service).to receive(:vmdb).with(:miq_request).and_return(svc_vmdb_handle_request)
    allow(ae_service).to receive(:vmdb).with(:conversion_host).and_return(svc_vmdb_handle_conversion_host)
    allow(ae_service).to receive(:vmdb).with(:service_template_transformation_plan_task).and_return(svc_vmdb_handle_transformation_task)

    allow(svc_vmdb_handle_conversion_host).to receive(:all).and_return([svc_model_conversion_host_1, svc_model_conversion_host_2, svc_model_conversion_host_3])
    allow(svc_model_transformation_task_1).to receive(:transformation_destination).with(svc_model_src_cluster).and_return(svc_model_dst_cluster)
    allow(svc_model_conversion_host_1).to receive(:ext_management_system).and_return(svc_model_dst_ems_1)
    allow(svc_model_conversion_host_2).to receive(:ext_management_system).and_return(svc_model_dst_ems_1)
    allow(svc_model_conversion_host_3).to receive(:ext_management_system).and_return(svc_model_dst_ems_2)
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
    it "filter out invalid request" do
      allow(svc_vmdb_handle_request).to receive(:where).with(:request_state => 'active', :type => 'AutomationRequest').and_return([svc_model_automation_request_1, svc_model_automation_request_3])
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
    before do
      ae_service.root['automation_task'] = svc_model_automation_task
      allow(svc_vmdb_handle_request).to receive(:where).with(:request_state => 'active', :type => 'AutomationRequest').and_return([svc_model_automation_request_1, svc_model_automation_request_2])
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
      user_admin = FactoryBot.create(:user, :userid => 'admin')
      expect(ae_service).to receive(:execute).with(
        :create_automation_request,
        {
          :namespace     => 'Transformation/StateMachines',
          :class_name    => 'TransformationThrottler',
          :instance_name => 'Default',
          :user_id       => user_admin.id,
          :attrs         => { :ttl => 3600 }
        },
        'admin',
        true
      )
      described_class.launch(ae_service)
    end
  end

  context "#retry_or_die" do
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
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([])
      described_class.retry_or_die(ae_service)
      expect(ae_service.root['ae_result']).to be_nil
    end

    it "with active transformation task" do
      ae_service.root['ae_state_max_retries'] = 60
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1])
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
    it "calls the correct method" do
      expect(described_class).to receive(:schedule_tasks_fifo).with(ae_service)
      described_class.schedule_tasks(ae_service)
    end
  end

  context "#schedule_tasks_fifo" do
    before do
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1])
    end

    it "doesn't assign host when none is eligible" do
      described_class.schedule_tasks_fifo(ae_service)
      expect(svc_model_transformation_task_1.conversion_host).to be_nil
    end

    it "assigns the only one slot available" do
      allow(svc_model_conversion_host_1).to receive(:eligible?).and_return(true)
      described_class.schedule_tasks_fifo(ae_service)
      expect(svc_model_transformation_task_1.conversion_host.id).to eq(svc_model_conversion_host_1.id)
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
    it "without active transformation task" do
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([])
      expect(described_class.active_transformation_tasks(ae_service)).to eq([])
    end

    it "with active transformation task" do
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1])
      expect(described_class.active_transformation_tasks(ae_service).first.id).to eq(svc_model_transformation_task_1.id)
    end
  end

  context "#unassigned_transformation_tasks" do
    it "filter out assigned transformation task" do
      allow(svc_vmdb_handle_transformation_task).to receive(:where).with(:state => 'active').and_return([svc_model_transformation_task_1, svc_model_transformation_task_2])
      allow(svc_model_transformation_task_1).to receive(:conversion_host).and_return(svc_model_conversion_host_1)
      expect(described_class.unassigned_transformation_tasks(ae_service).length).to eq(1)
      expect(described_class.unassigned_transformation_tasks(ae_service).first.id).to eq(svc_model_transformation_task_2.id)
    end
  end

  describe "#transformation_hosts" do
    before do
      allow(svc_model_transformation_task_1).to receive(:conversion_host).and_return(svc_model_conversion_host_1)
      allow(svc_model_transformation_task_2).to receive(:conversion_host).and_return(svc_model_conversion_host_2)
      allow(svc_model_transformation_task_3).to receive(:conversion_host).and_return(nil)
    end

    it "returns the conversion hosts for the EMS" do
      expect(described_class.transformation_hosts(svc_model_dst_ems_1, ae_service)).to eq([svc_model_conversion_host_1, svc_model_conversion_host_2])
    end
  end

  describe "#eligible_transformation_hosts" do
    it "returns the eligble hosts" do
      allow(svc_model_conversion_host_1).to receive(:eligible?).and_return(true)
      allow(svc_model_conversion_host_2).to receive(:eligible?).and_return(true)
      allow(svc_model_conversion_host_1).to receive(:active_tasks).and_return([svc_model_transformation_task_1, svc_model_transformation_task_2])
      allow(svc_model_conversion_host_2).to receive(:active_tasks).and_return([svc_model_transformation_task_3])
      expect(described_class.eligible_transformation_hosts(svc_model_dst_ems_1, ae_service)).to eq([svc_model_conversion_host_2, svc_model_conversion_host_1])
    end
  end

  describe "#get_runners_count_by_ems" do
    it "returns the number of runners" do
      allow(svc_model_conversion_host_1).to receive(:active_tasks).and_return([svc_model_transformation_task_1, svc_model_transformation_task_2])
      allow(svc_model_conversion_host_2).to receive(:active_tasks).and_return([svc_model_transformation_task_3])
      expect(described_class.get_runners_count_by_ems(svc_model_dst_ems_1, ae_service)).to eq(3)
    end
  end

  describe "#ems_max_runners" do
    it "with custom attribute" do
      allow(svc_model_dst_ems_1).to receive(:custom_get).with('Max Transformation Runners').and_return('2')
      expect(described_class.ems_max_runners(svc_model_dst_ems_1, {})).to eq(2)
    end

    it "with factory_config key" do
      expect(described_class.ems_max_runners(svc_model_dst_ems_1, {'ems_max_runners' => 2}, ae_service)).to eq(2)
    end

    it "with overridden max_runners" do
      expect(described_class.ems_max_runners(svc_model_dst_ems_1, {}, 2)).to eq(2)
    end

    it "with default" do
      expect(described_class.ems_max_runners(svc_model_dst_ems_1, {})).to eq(10)
    end
  end

  describe "#get_transformation_host" do
    before do
      allow(svc_model_conversion_host_1).to receive(:active_tasks).and_return([svc_model_transformation_task_1, svc_model_transformation_task_2])
      allow(svc_model_conversion_host_2).to receive(:active_tasks).and_return([svc_model_transformation_task_3])
      allow(svc_model_transformation_task_1).to receive(:conversion_host).and_return(svc_model_conversion_host_1)
      allow(svc_model_transformation_task_2).to receive(:conversion_host).and_return(svc_model_conversion_host_2)
      allow(svc_model_transformation_task_3).to receive(:conversion_host).and_return(nil)
    end

    it "when ems max runners is reached" do
      expect(described_class.get_transformation_host(svc_model_transformation_task_3, { 'ems_max_runners' => 2 }, ae_service)).to be_nil
    end

    it "without an eligible host" do
      allow(svc_model_conversion_host_1).to receive(:eligible?).and_return(false)
      allow(svc_model_conversion_host_2).to receive(:eligible?).and_return(false)
      expect(described_class.get_transformation_host(svc_model_transformation_task_3, {}, ae_service)).to be_nil
    end

    it "with an eligible host" do
      allow(svc_model_conversion_host_1).to receive(:eligible?).and_return(true)
      allow(svc_model_conversion_host_2).to receive(:eligible?).and_return(true)
      expect(described_class.get_transformation_host(svc_model_transformation_task_3, {}, ae_service)).to eq(svc_model_conversion_host_2)
    end
  end
end
