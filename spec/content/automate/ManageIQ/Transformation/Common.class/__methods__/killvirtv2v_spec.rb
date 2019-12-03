require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Common.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Common::KillVirtV2V do
  let(:user) { FactoryBot.create(:user_with_email_and_group) }
  let(:group) { FactoryBot.create(:miq_group) }
  let(:task) { FactoryBot.create(:service_template_transformation_plan_task) }

  let(:svc_model_user) { MiqAeMethodService::MiqAeServiceUser.find(user.id) }
  let(:svc_model_group) { MiqAeMethodService::MiqAeServiceMiqGroup.find(group.id) }
  let(:svc_model_task) { MiqAeMethodService::MiqAeServiceServiceTemplateTransformationPlanTask.find(task.id) }

  let(:conversion_state) do
    {
      "started"    => true,
      "disks"      => [{ "path" => "[datastore] test_vm/test_vm.vmdk", "progress" => 25 }],
      "pid"        => 141_350,
      "disk_count" => 1
    }
  end

  let(:time_now) { Time.now.utc }

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

  before do
    allow(ManageIQ::Automate::Transformation::Common::Utils).to receive(:task).and_return(svc_model_task)
    allow(svc_model_task).to receive(:get_conversion_state).and_return(conversion_state)
  end

  describe "#task_virtv2v_state" do
    it "returns nil if virt_v2v has not started" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return(nil)
      expect(described_class.new(ae_service).task_virtv2v_state).to be_nil
    end

    it "returns nil if virt_v2v has finished" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(time_now)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(time_now + 1200)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return(nil)
      expect(described_class.new(ae_service).task_virtv2v_state).to be_nil
    end

    it "returns nil if virt_v2v_wrapper has no information" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(time_now)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return(nil)
      expect(described_class.new(ae_service).task_virtv2v_state).to be_nil
    end

    it "returns a hash if virt_v2v is still running" do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(time_now)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return('fake_key' => 'fave_value')
      expect(described_class.new(ae_service).task_virtv2v_state).to eq(conversion_state)
    end
  end

  describe "#kill_signal" do
    it "returns KILL if gracefull kill has already been sent" do
      allow(ae_service).to receive(:get_state_var).with('virtv2v_graceful_kill').and_return(true)
      expect(described_class.new(ae_service).kill_signal).to eq('KILL')
    end

    it "returns TERM and retries if gracefull kill has not been sent" do
      allow(ae_service).to receive(:get_state_var).with('virtv2v_graceful_kill').and_return(false)
      expect(described_class.new(ae_service).kill_signal).to eq('TERM')
      expect(ae_service.root['ae_result']).to eq('retry')
      expect(ae_service.root['ae_retry_interval']).to eq('30.seconds')
    end
  end

  describe "#main" do
    before do
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_started_on).and_return(time_now)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_finished_on).and_return(nil)
      allow(svc_model_task).to receive(:get_option).with(:virtv2v_wrapper).and_return('fake_key' => 'fave_value')
    end

    it "returns true if kill succeeds" do
      allow(svc_model_task).to receive(:kill_virtv2v).and_return(true)
      expect(described_class.new(ae_service).main).to eq(true)
    end

    it "raises if kill_virtv2v fails" do
      errormsg = 'Unexpected error'
      allow(svc_model_task).to receive(:kill_virtv2v).and_raise(errormsg)
      expect { described_class.new(ae_service).main }.to raise_error(errormsg)
      expect(ae_service.get_state_var(:ae_state_progress)).to eq('message' => errormsg)
    end
  end
end
