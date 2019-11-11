require_domain_file

describe ManageIQ::Automate::System::CommonMethods::QuotaStateMachine::Rejected do
  include Spec::Support::AutomationHelper

  let(:admin) { FactoryBot.create(:user_with_email_and_group, :name => 'admin', :userid => 'admin') }
  let(:ems) { FactoryBot.create(:ems_vmware_with_authentication) }
  let(:vm_template) { FactoryBot.create(:template_vmware, :ext_management_system => ems) }

  let(:miq_provision_request) do
    FactoryBot.create(:miq_provision_request,
                      :src_vm_id => vm_template.id,
                      :requester => admin)
  end

  let(:root_hash) { { 'miq_request' => svc_miq_request } }
  let(:svc_miq_request) { MiqAeMethodService::MiqAeServiceMiqRequest.find(miq_provision_request.id) }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_hash).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      service.object = current_object
    end
  end

  context "Quota exceeded" do
    let(:denied_msg) { 'VM Provisioning - Request Created' }

    it "rejected with log message" do
      expect(ae_service).to receive(:create_notification).with(:level   => 'error',
                                                               :message => 'Quota Exceeded: VM Provisioning - Request Created',
                                                               :subject => svc_miq_request)
      expect(svc_miq_request).to(receive(:deny).with('admin', 'Quota Exceeded'))
      expect(ae_service).to receive(:log).with('info', "Request denied because of #{miq_provision_request.message}")

      described_class.new(ae_service).main

      expect(svc_miq_request.message).to eql(denied_msg)
    end
  end
end
