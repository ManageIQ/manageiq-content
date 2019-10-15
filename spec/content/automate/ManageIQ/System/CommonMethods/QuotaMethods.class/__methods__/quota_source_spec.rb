require_domain_file

describe ManageIQ::Automate::System::CommonMethods::QuotaMethods::QuotaSource do
  include Spec::Support::QuotaHelper

  let!(:model) { setup_model }
  let(:root_hash) do
    {
      'miq_provision_request' => svc_miq_request,
      'miq_request'           => svc_miq_request,
      'quota_source'          => quota_source,
      'quota_source_type'     => quota_source_type
    }
  end

  let(:svc_miq_request) { MiqAeMethodService::MiqAeServiceMiqRequest.find(@miq_request.id) }

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(root_hash)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  shared_examples_for "quota_source" do
    it "request_info" do
      described_class.new(ae_service).main

      expect(ae_service.root['quota_source_type']).to eq(quota_source_type)
    end
  end

  context "returns ok for 'group' as quota source" do
    let(:quota_source) { MiqAeMethodService::MiqAeServiceMiqGroup.find(@miq_group.id) }
    let(:quota_source_type) { 'group' }

    it_behaves_like "quota_source"
  end

  context "returns ok for 'user' as quota source" do
    let(:quota_source) { MiqAeMethodService::MiqAeServiceUser.find(@user.id) }
    let(:quota_source_type) { 'user' }

    it_behaves_like "quota_source"
  end

  context "returns ok for 'tenant' as quota source" do
    let(:quota_source) { MiqAeMethodService::MiqAeServiceTenant.find(@tenant.id) }
    let(:quota_source_type) { 'tenant' }

    it_behaves_like "quota_source"
  end
end
