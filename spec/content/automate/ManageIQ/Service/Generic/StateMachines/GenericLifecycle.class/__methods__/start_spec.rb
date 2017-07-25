require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::GenericLifecycle::Start do
  let(:request) { FactoryGirl.create(:service_template_provision_request, :requester => FactoryGirl.create(:user_admin)) }
  let(:job_template) { FactoryGirl.create(:ansible_configuration_script, :manager => FactoryGirl.create(:automation_manager)) }
  let(:service_ansible_tower) { FactoryGirl.create(:service_ansible_tower, :job_template => job_template, :options => config_info_options) }
  let(:svc_service) { MiqAeMethodService::MiqAeServiceServiceAnsibleTower.find(service_ansible_tower.id) }
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision',
                  'ae_state_max_retries' => 100)
  end
  let(:ae_service) { Spec::Support::MiqAeMockService.new(root_object) }
  let(:config_info_options) do
    {
      :config_info => {
        :provision  => {
          :execution_ttl => ttl
        },
        :retirement => {
          :execution_ttl => ttl
        }
      }
    }
  end

  shared_examples_for "#ttl" do
    it "check" do
      allow(ae_service).to receive(:create_notification)

      described_class.new(ae_service).main
      expect(ae_service.root['ae_retry_interval']).to eq(ae_retry_interval)
    end
  end

  context "Start 7700 ttl, 100 retries eq interval 77" do
    let(:ae_retry_interval) { 77 }
    let(:ttl) { 7700 }
    it_behaves_like "#ttl"
  end

  context "Start 60000 ttl, 100 retries eq interval 600" do
    let(:ae_retry_interval) { 600 }
    let(:ttl) { 60_000 }
    it_behaves_like "#ttl"
  end

  context "Start 600 ttl, 100 retries interval nil" do
    let(:ae_retry_interval) { nil }
    let(:ttl) { 600 }
    it_behaves_like "#ttl"
  end

  context "Start 0 ttl, 100 retries, interval nil" do
    let(:ae_retry_interval) { nil }
    let(:ttl) { 0 }
    it_behaves_like "#ttl"
  end

  context "Start retirement tests, " do
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Retirement', 'ae_state_max_retries' => 100)
    end

    context " 7700 ttl, 100 retries eq interval 77" do
      let(:ae_retry_interval) { 77 }
      let(:ttl) { 7700 }
      it_behaves_like "#ttl"
    end

    context " 60000 ttl, 100 retries eq interval 600" do
      let(:ae_retry_interval) { 600 }
      let(:ttl) { 60_000 }
      it_behaves_like "#ttl"
    end

    context " 600 ttl, 100 retries eq interval nil" do
      let(:ae_retry_interval) { nil }
      let(:ttl) { 600 }
      it_behaves_like "#ttl"
    end

    context " 0 ttl, 100 retries, interval nil" do
      let(:ae_retry_interval) { nil }
      let(:ttl) { 0 }
      it_behaves_like "#ttl"
    end
  end

  context "Start 6000 ttl, 50 retries eq interval 120" do
    let(:ae_retry_interval) { 120 }
    let(:ttl) { 6000 }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision', 'ae_state_max_retries' => 50)
    end
    it_behaves_like "#ttl"
  end

  context "Start 6000 ttl, 0 retries eq interval nil" do
    let(:ae_retry_interval) { nil }
    let(:ttl) { 6000 }
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new('service' => svc_service, 'service_action' => 'Provision', 'ae_state_max_retries' => 0)
    end
    it_behaves_like "#ttl"
  end
end
