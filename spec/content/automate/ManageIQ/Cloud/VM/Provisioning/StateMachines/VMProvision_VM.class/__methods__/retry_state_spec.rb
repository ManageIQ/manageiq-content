require_domain_file

describe ManageIQ::Automate::Service::Generic::StateMachines::VMProvision_VM::RetryState do
  describe "#retry_state" do
    let(:user) { FactoryGirl.create(:user) }
    let(:ems) { FactoryGirl.create(:ems_openstack_with_authentication) }
    let(:vm_template) { FactoryGirl.create(:template_openstack, :ext_management_system => ems) }
    let(:miq_request) do
      FactoryGirl.create(:miq_provision_request,
                         :provision_type => 'template',
                         :state          => 'pending',
                         :status         => 'Ok',
                         :src_vm_id      => vm_template.id,
                         :requester      => user)
    end
    let(:miq_server) { MiqServer.new }
    let(:provision) do
      MiqProvision.new.tap do |prov|
        prov.miq_request = miq_request
        prov.message = "An error occurred while provisioning Instance 1"
      end
    end
    let(:root_object) do
      Spec::Support::MiqAeMockObject.new.tap do |ro|
        ro["miq_provision"] = provision
        ro["miq_server"]    = miq_server
        ro["ae_result"]     = "error"
        ro["ae_next_state"] = "some_state"
      end
    end
    let(:ae_service) do
      Spec::Support::MiqAeMockService.new(root_object).tap do |ae|
        ae.inputs = {}
      end
    end

    it "retries and increments count because of a matching error" do
      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_next_state']).to eq("some_state")
      expect(ae_service.get_state_var(:state_retries)).to eq(nil)

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq("restart")
      expect(ae_service.root['ae_next_state']).to eq("Placement")
      expect(ae_service.get_state_var(:state_retries)).to eq(1)
      expect(miq_request[:options][:user_message]).to include("Restarting from Placement")
    end

    it "remains in error and does not retry if the max tries have been reached" do
      ae_service.inputs["max_retries"] = 3
      ae_service.set_state_var(:state_retries, 3)
      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_next_state']).to eq("some_state")

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_next_state']).to eq("some_state")
      expect(ae_service.get_state_var(:state_retries)).to eq(3)
      expect(miq_request[:options][:user_message]).not_to include("Restarting")
    end

    it "remains in error and does not retry for an error that does not match" do
      ae_service.inputs["error_to_catch"] = "non-matching error"
      expect(ae_service.get_state_var(:state_retries)).to eq(nil)
      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_next_state']).to eq("some_state")

      described_class.new(ae_service).main

      expect(ae_service.root['ae_result']).to eq("error")
      expect(ae_service.root['ae_next_state']).to eq("some_state")
      expect(ae_service.get_state_var(:state_retries)).to eq(nil)
      expect(miq_request[:options][:user_message]).not_to include("Restarting")
    end
  end
end
