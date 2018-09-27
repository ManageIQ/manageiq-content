require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/TransformationHosts/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::TransformationHosts::Common::KillVirtV2V do
  let(:user) { FactoryGirl.create(:user_with_email_and_group) }
  let(:task) { FactoryGirl.create(:service_template_transformation_plan_task) }
  let(:host) { FactoryGirl.create(:host) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }
  let(:svc_model_host) { MiqAeMethodService::MiqAeServiceHost.find(host.id) }

  let(:root) do
    Spec::Support::MiqAeMockObject.new(
      'current'             => current_object,
      'user'                => svc_model_user,
      'state_machine_phase' => 'cleanup'
    )
  end

  let(:current_object) { Spec::Support::MiqAeMockObject.new }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root
      service.object = current_object
    end
  end

  let(:svc_vmdb_handle_host) { MiqAeMethodService::MiqAeServiceHost }

  before do
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).with(ae_service).and_return(svc_model_task)
    allow(svc_model_task).to receive(:get_option).with(:transformation_host_id).and_return(svc_model_host.id)

    allow(ae_service).to receive(:vmdb).with(:host).and_return(svc_vmdb_handle_host)
    allow(svc_vmdb_handle_host).to receive(:find_by).with(:id => svc_model_host.id).and_return(svc_model_host)
  end

  before(:each) do
    ManageIQ::Automate::Transformation::TransformationHosts::Common::KillVirtV2V.instance_variable_set(:@task, nil)
  end

  context "#task_virtv2v_state" do
    it "when virtv2v not started" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(nil)
      expect(described_class.new(ae_service).task_virtv2v_state(svc_model_host)).to be_nil
    end

    it "when virtv2v is finished" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(Time.now.utc - 1)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(Time.now.utc)
      expect(described_class.new(ae_service).task_virtv2v_state(svc_model_host)).to be_nil
    end

    it "when virtv2v-wrapper has failed" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(Time.now.utc - 1)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return(nil)
      expect(described_class.new(ae_service).task_virtv2v_state(svc_model_host)).to be_nil
    end

    it "when remote command fails" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(Time.now.utc - 1)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return('state_file' => '/tmp/fake_state_file.state')
      allow(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, "cat '/tmp/fake_state_file.state'").and_return(:success => false, :stdout => 'No such file or directory')
      expect(described_class.new(ae_service).task_virtv2v_state(svc_model_host)).to be_nil
    end

    it "when state file is empty" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(Time.now.utc - 1)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return('state_file' => '/tmp/fake_state_file.state')
      allow(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, "cat '/tmp/fake_state_file.state'").and_return(:success => true, :stdout => '')
      expect(described_class.new(ae_service).task_virtv2v_state(svc_model_host)).to be_nil
    end

    it "when state file is ok" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(Time.now.utc - 1)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return('state_file' => '/tmp/fake_state_file.state')
      allow(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, "cat '/tmp/fake_state_file.state'").and_return(:success => true, :stdout => '{ "pid": "1234" }')
      expect(described_class.new(ae_service).task_virtv2v_state(svc_model_host)).to eq('pid' => '1234')
    end
  end

  context "#kill_virtv2v" do
    it "when virtv2v has not received SIGTERM" do
      allow(ae_service).to receive(:get_state_var).with('virtv2v_graceful_kill').and_return(nil)
      expect(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, 'kill -s TERM 1234')
      described_class.new(ae_service).kill_virtv2v(svc_model_host, '1234')
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq('30.seconds')
    end

    it "when virtv2v has not received SIGTERM" do
      allow(ae_service).to receive(:get_state_var).with('virtv2v_graceful_kill').and_return(true)
      expect(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, 'kill -s KILL 1234')
      described_class.new(ae_service).kill_virtv2v(svc_model_host, '1234')
    end
  end

  context "#main" do
    it "wraping up" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(Time.now.utc - 1)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return('state_file' => '/tmp/fake_state_file.state')
      allow(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, "cat '/tmp/fake_state_file.state'").and_return(:success => true, :stdout => '{ "pid": "1234" }')
      allow(ae_service).to receive(:get_state_var).with('virtv2v_graceful_kill').and_return(true)
      expect(ManageIQ::Automate::Transformation::TransformationHosts::Common::Utils).to receive(:remote_command).with(svc_model_task, svc_model_host, 'kill -s KILL 1234')
      described_class.new(ae_service).main
    end
  end

  context "catchall exception rescue" do
    before do
      allow(svc_model_task).to receive(:get_option).with(:transformation_host_id).and_raise(StandardError.new('kaboom'))
    end
    it "forcefully raise" do
      expect { described_class.new(ae_service).main }.to raise_error('kaboom')
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => 'kaboom')
    end
  end
end
